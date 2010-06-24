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

                initializer: function() {
                    // Y.log('tabpanel::initializer');

                    var tab = this.get('host');
                    tab.on('selectedChange', Y.bind(this.afterSelectedChange, this));
                },

                initStdMod: function(panel) {
                    // Y.log('tabpanel::initStdMod');
                    panel = panel ? panel : this.get('host').get('panelNode');
                    panel.setContent(''); // clean slate
                    /*
                    Y.log('panel -> contentBox');
                    Y.log(panel);
                    Y.log(this.get('contentBox'));
                    */
                    this.set('contentBox', panel);
                    this._stdModNode = panel;
                    this.set('headerContent', 1);
                    this.set('bodyContent', 1);
                    this.set('footerContent', 1);  
                    this._renderUIStdMod();
                    this._bindUIStdMod();
                    this.populateTab(this);
                },
                
                populateTab: function (tab) {
                    // Y.log('tabpanel::populateTab');

                    // first, deal with recursion
                    if (tab.get('related')) {
                        tab.addRelated(tab.get('related'));
                    }

                    // if there's nothing left to recurse, add the rest
                    else {
                        if (tab.get('content')) {
                            tab.addContent(tab.get('content'));
                        }
                        if (tab.get('uri')) {
                            tab.prepareSrc();
                        }
                    }
                },

                afterSelectedChange: function (e) {
                    // Y.log('tabpanel::afterSelectedChange');

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

                addContent: function (content) {
                    // Y.log('tabpanel::addContent');
                    var content_node = this._buildEmptyContentNode();
                    if (Y.Lang.isString(content)) {
                        content_node.setContent(content);
                    }
                    else if (Y.Lang.isObject(content)) {
                        content_node.setContent(
                            this._buildContentString(content)
                        );
                    }
                    this.set('headerContent', content_node);
                },

                prepareSrc: function() {
                    // Y.log('tabpanel::prepareSrc');
                    var src_node = this._buildEmptySrcNode();
                    src_node.setContent('');
                    this.set('bodyContent', src_node);
                },

                addSrc: function(response) {
                    // Y.log('tabpanel::addSrc');
                    if (response) {
                        var data = this._parseJSON(response);
                        // Y.log(data);
                        var content_str = this._buildContentString(data);
                        var src_node = this._buildEmptySrcNode();
                        src_node.setContent(content_str);
                        if (Y.Lang.isValue(response.related)) {
                            this.addRelated(response.related, src_node);
                        }
                        this.set('bodyContent', src_node);
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

                _buildContentString: function (data) {
                    // Y.log('tabpanel::_buildContentString');
                    var content = ['<dl>'];
                    Y.each(data, function (v, k) {
                        if (Y.Lang.isString(v) || Y.Lang.isNumber(v)) {
                            content.push('<dt>' + k + ': </dt><dd>' + v + '&nbsp;</dd>');
                        }
                        else if (k === 'action_log') {
                            // build the action log, but don't render it here.
                        }
                        else if (Y.Lang.isArray(v) && Y.Lang.isObject(v[0]) && Y.Lang.isValue(v[0].field)) {
                            Y.each(v, function (o) {
                                content.push('<dt>' + o.field + ': </dt><dd>' + o.value + '&nbsp;</dd>');
                            });
                        }
                        else if (Y.Lang.isObject(v)) {
                            content.push(this._buildContentString(v));
                        }
                    }, this);
                    content.push('</dl>');
                    return content.join('');
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
                                exp_col ='\
  <span class="treeview-action first treeview-expand">Expand All</span> | \
  <span class="treeview-action treeview-collapse">Collapse All</span>';
                            }
                            items[v.order] = Y.Node.create('\
<li class="' + li_class + '">\
  <span class="treeview-label treeview-toggle">' + v.label + '</span>\
' + exp_col + '\
</li>');
                            var mtp_node = Y.Node.create('\
<div class="yui3-tab-panel yui3-tab-panel-selected yui3-widget-stdmod">Loading...</div>');

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
                            items[v.order].append(mtp_node);
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
                    // build an array of dependents to return
                    var ary = [container.mtp];
                    var dependents = container.all(
                        'li.yui3-treeviewlite-dependent'
                    );
                    Y.each(dependents, function (v, k) {
                        var dep_stdmod = v.one('div.yui3-widget-stdmod');
                        ary.push(dep_stdmod.mtp);
                    });
                    return ary;
                },

                _onOpen: function (e) {
                    // Y.log('tabpanel::_onOpen  e -> div');
                    var div = e.details[0].target.get('parentNode')
                        .one('div.yui3-widget-stdmod');

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
                    var div = e.details[0].target.get('parentNode')
                        .one('div.yui3-widget-stdmod');

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
        
        Y.namespace("IC");
        Y.IC.ManageTabPanel = ManageTabPanel;

    },
    "@VERSION@",
    {
        requires: [
            "gallery-widget-io",
            "widget-stdmod",
            "gallery-treeviewlite"
        ]
    }
);
