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

                _dummy_details: {
                    "renderer": {
                        "name": "ManageRevisionDetails",
                        "config": {}
                    },
                    "pk_settings": [
                        {
                            "value": 6,
                            "field": "id"
                        }
                    ],
                    "auto_settings": [
                        {
                            "value": "2009-11-30T11:01:00",
                            "field": "date_created"
                        },
                        {
                            "value": "2009-11-30T11:01:11",
                            "field": "last_modified"
                        },
                        {
                            "value": "",
                            "field": "created_by"
                        },
                        {
                            "value": "",
                            "field": "modified_by"
                        }
                    ],
                    "foreign_objects": [
                        {
                            "value": "web",
                            "display": "Web",
                            "field": "Order Kind"
                        }
                    ],
                    "object_name": "Order",
                    "action_log": [
                        {
                            "by_name": "",
                            "content": "through checkout",
                            "date_created": "2009-11-30T11:01:00",
                            "label": "Row Created",
                            "details": [
                                "kind_code: web",
                                "status_code: new"
                            ]
                        },
                        {
                            "by_name": "",
                            "content": "",
                            "date_created": "2009-11-30T11:01:00",
                            "label": "Status Change",
                            "details": [
                                "from 'new' to '3d_auth_request_pending'"
                            ]
                        },
                        {
                            "by_name": "",
                            "content": "",
                            "date_created": "2009-11-30T11:01:03",
                            "label": "Status Change",
                            "details": [
                                "from '3d_auth_request_pending' to '3d_auth_requested'"
                            ]
                        },
                        {
                            "by_name": "",
                            "content": "",
                            "date_created": "2009-11-30T11:01:10",
                            "label": "Status Change",
                            "details": [
                                "from '3d_auth_requested' to '3d_auth_returned'"
                            ]
                        },
                        {
                            "by_name": "",
                            "content": "(from 3D auth result)",
                            "date_created": "2009-11-30T11:01:11",
                            "label": "Status Change",
                            "details": [
                                "from '3d_auth_returned' to 'revision_check_pending'"
                            ]
                        },
                        {
                            "by_name": "",
                            "content": "",
                            "date_created": "2009-11-30T11:01:11",
                            "label": "Status Change",
                            "details": [
                                "from 'revision_check_pending' to 'revision_pending'"
                            ]
                        }
                    ],
                    "other_settings": [
                        {
                            "value": 8,
                            "field": "billing_address_id"
                        },
                        {
                            "value": "",
                            "field": "comments"
                        },
                        {
                            "value": 8,
                            "field": "delivery_address_id"
                        },
                        {
                            "value": null,
                            "field": "delivery_date_authoritative"
                        },
                        {
                            "value": "2009-11-30",
                            "field": "delivery_date_preferred"
                        },
                        {
                            "value": "brian@endpoint.com",
                            "field": "email"
                        },
                        {
                            "value": "automated",
                            "field": "fraud_status_code"
                        },
                        {
                            "value": "24.74.61.172",
                            "field": "ip_address"
                        },
                        {
                            "value": null,
                            "field": "logistics_service_code"
                        },
                        {
                            "value": {
                                "local_rd_secs": 39660,
                                "local_rd_days": 733741,
                                "rd_nanosecs": 217529000,
                                "locale": {
                                    "default_time_format_length": "medium",
                                    "native_territory": "United States",
                                    "native_language": "English",
                                    "native_complete_name": "English United States",
                                    "en_language": "English",
                                    "id": "en_US",
                                    "default_date_format_length": "medium",
                                    "en_complete_name": "English United States",
                                    "en_territory": "United States"
                                },
                                "local_c": {
                                    "hour": 11,
                                    "second": 0,
                                    "month": 11,
                                    "quarter": 4,
                                    "day_of_year": 334,
                                    "day_of_quarter": 61,
                                    "minute": 1,
                                    "day": 30,
                                    "day_of_week": 1,
                                    "year": 2009},
                                "utc_rd_secs": 39660,
                                "formatter": null,
                                "tz": {
                                    "name": "floating",
                                    "offset": 0
                                },
                                "utc_year": 2010,
                                "utc_rd_days": 733741,
                                "offset_modifier": 0
                            },
                            "field": "order_date"
                        },
                        {
                            "value": "jWCu5YZF",
                            "field": "session"
                        },
                        {
                            "value": "revision_pending",
                            "field": "status_code"
                        }
                    ]
                },

                _actions: null,

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
                        // content (the stdmod hd) should never be too complex.
                        // - either a simple string or table.
                        // So it gets the default renderer
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
                        // debug with dummy data
                        if (this.get('label') === '0 - Details' ||
                           this.get('label') === '8 - Line') {
                            data = this._dummy_details;
                        }
                        var src_node = this._buildEmptySrcNode();
                        // check to see what renderer we should use
                        var renderer, content;
                        if (Y.Lang.isValue(data.renderer)) 
                            renderer = data.renderer;
                        if (!renderer) {
                            content = this._buildContentString(data);
                            src_node.setContent(content);
                        }
                        else {
                            renderer = new Y.IC[renderer.name](renderer.config);
                            src_node = renderer.getContent(data, src_node);
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
                            content.push('<dt>' + k + ': </dt>' +
                                         '<dd>' + v + '&nbsp;</dd>');
                        }
                        else if (k === 'action_log') {
                            // skip these for now...
                        }
                        else if (Y.Lang.isArray(v) && 
                                 Y.Lang.isObject(v[0]) && 
                                 Y.Lang.isValue(v[0].field)) {
                            Y.each(v, function (o) {
                                content.push('<dt>' + o.field + ': </dt>' + 
                                             '<dd>' + o.value + '&nbsp;</dd>');
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
            "ic-manage-plugin-tabpanel-css",
            "ic-manage-renderers-revisiondetails",
            "gallery-widget-io",
            "widget-stdmod",
            "ic-manage-plugin-treeview"
        ]
    }
);
