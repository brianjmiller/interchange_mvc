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
    "ic-manage-plugin-tabpanel",
    function(Y) {

        var ManageTabPanel = Y.Base.create (
            "ic_manage_tabpanel",         // module identifier  
            Y.Plugin.WidgetIO,       // what to extend     
            [                        // classes to mix in  
                Y.WidgetStdMod
            ],
            {                        // prototype overrides/additions
                _actions: null,
                _default_renderer: {
                    name: 'ManageDefaultRenderer',
                    config: {}
                },

                initializer: function() {
                    // Y.log('tabpanel::initializer');
                    this.publish('manageTabPanel:srcloaded', {
                        broadcast:  1,   // instance notification
                        emitFacade: true // emit a facade so we get the event target
                    });
                    this.publish('manageTabPanel:contentloaded', {
                        broadcast:  1,   // instance notification
                        emitFacade: true // emit a facade so we get the event target
                    });

                    var tab = this.get('host');
                    tab.on(
                        'selectedChange', 
                        Y.bind(this._afterSelectedChange, this)
                    );
                    tab.on('ready', Y.bind(this._onReady, this));
                },

                initStdMod: function(panel) {
                    // Y.log('tabpanel::initStdMod');
                    panel.setContent(''); // clean slate

                    /*
                    Y.log('panel -> contentBox');
                    Y.log(panel);
                    Y.log(this.get('contentBox'));
                    */

                    this.set('contentBox', panel);
                    this._stdModNode = panel;

                    // never header..?
                    if (this.get('content') || this.get('uri')) {
                        this.set('bodyContent', 1);
                    }
                    if (this.get('related')) this.set('footerContent', 1);

                    this._renderUIStdMod();
                    this._bindUIStdMod();
                    this.populateTab(this);
                },
                
                populateTab: function (tab) {
                    // Y.log('tabpanel::populateTab - label:' + this.get('label'));

                    // first, deal with recursion
                    if (tab.get('related')) {
                        tab.addRelated(tab.get('related'));
                    }

                    // if there's nothing left to recurse, add the rest
                    else {
                        if (tab.get('content')) {
                            tab.addContent(tab.get('content'));
                        }
                        else if (tab.get('uri')) {
                            tab.prepareSrc();
                        }
                    }
                },

                setContent: function (content) {
                    // Y.log('tabpanel::setContent');
                    try {
                        this.get('host').get('contentBox').setContent(content);
                    } 
                    catch (err) {
                        Y.log('setContent error!  No contentBox?');
                        // does this need to be fixed? it works anyway...
                    }
                }, 

                addContent: function (data) {
                    // Y.log('tabpanel::addContent - data');
                    // Y.log(data);
                    var node = this._buildEmptyContentNode();
                    if (Y.Lang.isString(data)) {
                        node.setContent(data);
                    }
                    else if (Y.Lang.isObject(data)) {
                        var renderer;
                        if (Y.Lang.isValue(data.renderer)) {
                            renderer = data.renderer;
                        }
                        else {
                            renderer = this._default_renderer;
                        }
                        renderer = new Y.IC[renderer.name](renderer.config);
                        node = renderer.getContent(data, node);
                    }
                    this.set('bodyContent', node);
                    this.fire('manageTabPanel:contentloaded');
                },

                prepareSrc: function() {
                    // Y.log('tabpanel::prepareSrc');
                    var node = this._buildEmptyContentNode();
                    node.setContent('');
                    this.set('bodyContent', node);
                },

                addSrc: function(response) {
                    // Y.log('tabpanel::addSrc');
                    if (response) {
                        var data = this._parseJSON(response);
                        this.addContent(data);
                    }
                },

                addRelated: function (related_ary) {
                    // Y.log('tabpanel::addRelated');
                    var related_node = this._buildEmptyRelatedNode();
                    var tree = this._buildRelatedTreeview(related_ary);
                    tree.plug(Y.IC.ManageTreeview);
                    related_node.append(tree);
                    this.set('footerContent', related_node);
                    tree.treeviewLite.on('open', this._onOpen, this);
                    tree.treeviewLite.on('collapse', this._onCollapse, this);
                },

                _onReady: function (e) {
                    // Y.log('tabpanel::_onReady');
                    var panel = this.get('host').get('panelNode');
                    this.initStdMod(panel);
                },

                _afterSelectedChange: function (e) {
                    // Y.log('tabpanel::_afterSelectedChange');

                    // expand the 'src' if there is no treeview
                    if (e.newVal) {
                        var cb = this.get('contentBox');
                        if (cb && !cb.one('.yui3-treeviewlite')) { 
                            // tab has been selected, and there is no treeview
                            if (this.get('uri')) {
                                this.refresh();
                            }
                        }
                    }
                },

                _defStartHandler: function (id, o) {
                    // Y.log('tabpanel::_defStartHandler');
                    this._activeIO = o;
                    // this.setContent('');
                    // this._toggleLoadingClass(true);
                },

                _defSuccessHandler: function (id, o) {
                    // Y.log('tabpanel::_defSuccessHandler');
                    this.addSrc(o.responseText);
                },

                _parseJSON: function (json_str) {
                    // Y.log('tabpanel::_parseJSON');
                    var json = {};
                    try {
                        json = Y.JSON.parse(json_str);
                    }
                    catch (e) {
                        Y.log("Can't parse JSON: " + e, "error");
                        Y.log(json_str);
                    }
                    return json;
                },

                _buildRelatedTreeview: function (related_ary) {
                    // Y.log('tabpanel::_buildRelatedTreeview');
                    if (related_ary.length) {
                        var ul = Y.Node.create('<ul></ul>');
                        var items = [];
                        Y.each(related_ary, function (v, i) {
                            var li_class = 'yui3-treeviewlite-dependent';
                            var exp_col = ''; // expand | collapse
                            if (Y.Lang.isValue(v.related)) {
                                li_class = 'yui3-treeviewlite-collapsed';
                                exp_col = Y.IC.ManageTreeview.EXPAND_TEMPLATE +
                                    ' | ' + 
                                    Y.IC.ManageTreeview.COLLAPSE_TEMPLATE;
                            }
                            var label = Y.Node.create(
                                Y.IC.ManageTreeview.LABEL_NODE_TEMPLATE
                            );
                            label.setContent(v.label);
                            var item = Y.Node.create(
                                '<li class="' + li_class + '"></li>'
                            );
                            item.append(label).append(exp_col);
                            if (exp_col) {
                                item.one('span.treeview-expand')
                                    .addClass('first');
                            }
                            var mtp_node = Y.Node.create(
                                Y.IC.ManageTabPanel.MTP_NODE_TEMPLATE
                            );

                            /*
                            Y.log('----------------------------');
                            Y.log('label -> src -> content -> related');
                            Y.log(v.label);
                            Y.log(v.src || null);
                            Y.log(v.content || null);
                            Y.log(v.related || null);
                            Y.log('----------------------------');
                            */

                            mtp_node.plug(Y.IC.ManageTabPanel, {
                                label: v.label || null,
                                uri: v.src || null,
                                content: v.content || null,
                                related: v.related || null
                            });
                            // the following line recursively preps every related item
                            mtp_node.mtp.initStdMod(mtp_node);
                            item.append(mtp_node);
                            items[v.order] = item;
                        }, this);
                        Y.each(items, function (v) {
                            ul.append(v);
                        });
                        return ul;
                    }
                    else {
                        return Y.Node.create(
                            "<div>There seem to be related nodes - but I can't find them...</div>"
                        );
                    }
                },

                _getDependentPanels: function (container) {
                    // Y.log('tabpanel::_getDependentPanels');
                    // build an array of dependents to return
                    var ary = [container.mtp];
                    // NAM!!! this selector is fragile...
                    var dependents = container.all(
                        '>div>div>ul>li.yui3-treeviewlite-dependent'
                    );
                    Y.each(dependents, function (v, k) {
                        var dep_stdmod = v.one('div.yui3-widget-stdmod');
                        ary.push(dep_stdmod.mtp);
                    });
                    return ary;
                },

                _getTreeviewContainerForAction: function (e) {
                    // Y.log('tabpanel::_getTreeviewContainerForAction');
                    var target = e.details[0].target;
                    div = target.get('parentNode')
                        .one('div.yui3-widget-stdmod');

                    if (!div) {
                        // go up another level (must be the top level menu)
                        div = target.get('parentNode').get('parentNode')
                            .one('div.yui3-widget-stdmod');
                    }

                    return div;
                },

                _onOpen: function (e) {
                    // Y.log('tabpanel::_onOpen');
                    var div = this._getTreeviewContainerForAction(e);
                    // build an array of things that need opened
                    var opens = this._getDependentPanels(div);
                    Y.each(opens, function (v) {
                        // add any static content
                        var content = v.get('content');
                        if (content) {
                            v.addContent(content);
                        }
                        // start loading any dynamic content
                        var uri = v.get('uri');
                        if (uri) {
                            v.set('bodyContent', 'Loading...');
                            v.refresh();
                        }
                    });
                },

                _onCollapse: function (e) {
                    // Y.log('tabpanel::_onCollapse');
                    var div = this._getTreeviewContainerForAction(e);

                    // build an array of things that need collapses
                    var collapses = this._getDependentPanels(div);

                    Y.each(collapses, function (v) {
                        v.set('headerContent', '');
                        v.set('bodyContent', '');
                    });

                },

                _buildEmptyContentNode: function () {
                    return Y.Node.create(this.get('content_node_template'));
                },

                _buildEmptySrcNode: function () {
                    return Y.Node.create(this.get('src_node_template'));
                },

                _buildEmptyRelatedNode: function (data) {
                    return Y.Node.create(this.get('related_node_template'));
                },
                
                _toggleLoadingClass: function(add) {
                    // noop
                }

            }, {
                ATTRS: {
                    content_node_template: {
                        value: '<div class="yui3-tab-panel-content"></div>'
                    },
                    src_node_template: {
                        value: '<div class="yui3-tab-panel-src"></div>'
                    },
                    related_node_template: {
                        value: '<div class="yui3-tab-panel-related"></div>'
                    },
                    related: {
                        value: null
                    },
                    content: {
                        value: null
                    },
                    label: {
                        value: null
                    }
                },
                NAME: 'ic_manage_tab',
                NS: 'mtp'
            }
        );

        ManageTabPanel.MTP_NODE_TEMPLATE = '\
<div class="yui3-tab-panel yui3-tab-panel-selected yui3-widget-stdmod">Loading...</div>';

        Y.namespace("IC");
        Y.IC.ManageTabPanel = ManageTabPanel;

    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-plugin-tabpanel-css",
            "ic-manage-renderers-revisiondetails",
            "gallery-widget-io",
            "widget-stdmod",
            "ic-manage-plugin-treeview"
        ]
    }
);
