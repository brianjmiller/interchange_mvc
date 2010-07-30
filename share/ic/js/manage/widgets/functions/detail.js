/*
    Copyright (C) 2008-2010 End Point Corporation, http://www.endpoint.com/

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.
       
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see: http://www.gnu.org/licenses/ 
*/

YUI.add(
    "ic-manage-widget-function-detail",
    function(Y) {
        var ManageFunctionDetail;

        ManageFunctionDetail = function (config) {
            ManageFunctionDetail.superclass.constructor.apply(this, arguments);
            this.publish('manageFunctionDetail:tabsrendered', {
                broadcast:  1,   // instance notification
                emitFacade: true // emit a facade so we get the event target
            });
        };

        ManageFunctionDetail.NAME = "ic_manage_function_detail";

        Y.extend(
            ManageFunctionDetail,
            Y.IC.ManageFunction,
            {
                /*
                 * For an Order, this is the structure: 
                 *  _______   _____   _______   ________   _____
                 * |Details| |Goods| |History| |Payments| |Notes|
                 *  |         |       |         |          |
                 *  v         |       |         |          |
                 * Log        |       |         |          |
                 *            v       |         |          |
                 *(treeview) Line+[Inv|ntory Map|, Line, Li|e, ...
                 *                    |         |          |
                 *                    v         |          |
                 *        (treeview) Revision, R|vision, Re|ision, ...
                 *                       |      |          |
                 *                       v      |          |
                 *         (treeview) Line+[Elem|nt+[Parcel|ap]], Line, Line, ...
                 *                              |          |
                 *                              v          |
                 *                  (treeview) Transaction+|Allocation], Transaction, Transaction, ...
                 *                                 |       |
                 *                                 v       |
                 *                   (treeview) Line, Line,|Line...
                 *                                         |
                 *                                         v
                 *                             (treeview) Note, Note, Note
                 */

                _tabs: null,

                bindUI: function () {
                    this.on('visibleChange', Y.bind(this._onVisibleChange, this));
                },

                getHeaderText: function () {
                    // Y.log('detail::getHeaderText');
                    if (this._meta_data) {                        
                        var pks = this._meta_data.pk_settings[0];
                        var value = pks.value;
                        var header_desc = '';
                        if (this._meta_data.header_desc) {
                            header_desc = ' - ' + 
                                this._meta_data.header_desc + ' ';
                        }
                        var header = this._meta_data.object_name + ' Detail ' +
                            header_desc + '[' + value + ']';
                        // Y.log('detail::getHeaderText - header: ' 
                        //       + header + ' -> meta_data');
                        // Y.log(this._meta_data);
                        return header;
                    }
                    else {
                        // Y.log('detail::getHeaderText - ' +
                        //       'header is null - no meta_data');
                        return null;
                    }
                },

                _buildUI: function () {
                    // Y.log('detail::_buildUI');

                    if (! this.get('visible') ) return;

                    // NAM!!! to test with th edummy data, uncomment next line
                    // this._meta_data = this._dummy_data; // testing...

                    // the meta_data is already available, 
                    //  so build the outer tabs from it
                    var prefix = this.get('prefix') + '_ot';
                    this._tabs = new Y.IC.ManageTabView(
                        {
                            prefix: prefix
                        }
                    );
                    Y.each(this._meta_data.tabs, Y.bind(function (v, i) {
                        // Y.log('_meta_data.tab: ' + i);

                        /*
                        Y.log('v -> src -> related -> content');
                        Y.log(v);
                        Y.log(v.src);
                        Y.log(v.related);
                        Y.log(v.content);
                        */

                        this._tabs.add({
                            label: v.label, 
                            content: 'Loading...',
                            index: i,
                            plugins: [{
                                fn: Y.IC.ManageTabPanel,
                                cfg: {
                                    label: v.label || null,
                                    uri: v.src || null,
                                    content: v.content || null,
                                    related: v.related || null
                                }
                            }] 
                        }, i);
                    }, this));
                    this._tabs.after(
                        'render', 
                        Y.bind(this._afterOuterTabsRender, this)
                    );
                    this._content_node.setContent('');
                    this._tabs.render(this._content_node);
                    this.fire('manageFunction:loaded');
                },

                /*  Needs refactoring!
                 *  Even though this seems more appropriately a method
                 *  of tabview (or the tabpanel), it's here because
                 *  really there's no reason for it to be tied to tabs
                 *  at all.  If we have detail views without tabs, we
                 *  may want to add these nesting css classes there as
                 *  well.
                 */
                _afterOuterTabsRender: function (e) {
                    // Y.log('detail::_afterOuterTabsRender');
                    // run through each tabpanel
                    Y.each(this._tabs._tab_refs, function (v) {
                        var uls = v.tab.get('panelNode').all('ul');
                        // first add nesting classes
                        if (uls.size() > 0) {
                            Y.each(uls, function (v1, i1) {
                                var lis = v1.get('children');
                                // add level0, level1, level2, level0 ...
                                lis.addClass('level' + (i1 % 3));
                                lis.setAttribute('depth', i1);
                            }, this);
                        }
                        // then add a toplevel menu
                        if (uls.size() > 1) {
                            var ul = Y.one(uls._nodes[0]);
                            ul.treeviewLite.addTopLevelMenu(
                                v.tab.get('panelNode')
                            );
                        }
                    }, this);
                    // then select the correct tab from our state
                    // (there may not be any tabs, if the data is bad...)
                    try {
                        var tab_index = e.target.get('state.st') || 0;
                        e.target.selectChild(Number(tab_index));
                    } 
                    catch (err) {
                        Y.log(err);
                    }
                    this.fire('manageFunctionDetail:tabsrendered');
                },

                /*
                 * if this widget is hidden, remove it's history
                 * variables.  This is only necessary because the tabs
                 * are contained in the detail widget, and are not
                 * hidden themselves when the detail widget gets
                 * hidden.  Would making this module a Widget_Parent
                 * solve this problem?  How to let the hide/show
                 * events trickle down to the contained widgets?
                 */
                _onVisibleChange: function (e) {
                    // Y.log('detail::_onVisibleChange');
                    if (this._tabs) {
                        if (e.newVal === false) {
                            this._tabs.hide();
                        }
                        else {
                            this._tabs.show();
                        }
                    }
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageFunctionDetail = ManageFunctionDetail;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-widget-function",
            "ic-manage-widget-tabview",
            "ic-manage-plugin-tabpanel"
        ]
    }
);
