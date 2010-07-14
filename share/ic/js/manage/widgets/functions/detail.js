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
                _dummy_data: {
                    object_name: "Order",
                    pk_settings: [
                        {
                            "value": 6,
                            "field": "id"
                        }
                    ],
                    tabs: [
                        {
                            order: 0,
                            label: '0 - Summary',
                            src: '/manage/function/Orders_orderDetailView/0?_mode=config&_format=json&_pk_id=6',
                            content: {
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
                            }
                        },
                        {
                            order: 1,
                            label: '1 - Goods',
                            related: [
                                {
                                    order: 0,
                                    label: '2 - Line',
                                    src: '/manage/function/Variants_variantDetailView/0?_mode=config&_format=json&_pk_id=1',
                                    related: [
                                        {
                                            order: 0,
                                            label: '3 - Inventory Map',
                                            content: {
                                                Description: 10,
                                                Status: 'Pending Return',
                                                Location: '',
                                                Condition: 'New',
                                                'Send Revision Element #': 2,
                                                Status: 'Shipped',
                                                'Receive Revision Element #': 14,
                                                Status: 'Pending Return'
                                            },
                                            related: [
                                                {
                                                    order: 0,
                                                    label: '4 - Inventory Record',
                                                    src: '/manage/function/Inventories_recordDetailView/0?_mode=config&_format=json&_pk_id=13'
                                                }
                                            ]
                                        },
                                        {
                                            order: 1,
                                            label: '5 - Inventory Map',
                                            content: {
                                                Description: 22,
                                                Status: 'Dynamic Sold',
                                                Location: '',
                                                Condition: 'New',
                                                'Send Revision Element #': 15,
                                                Status: 'Dynamic Sold'
                                            },
                                            related: [
                                                {
                                                    order: 0,
                                                    label: '6 - Inventory Record',
                                                    src: '/manage/function/Inventories_recordDetailView/0?_mode=config&_format=json&_pk_id=26'
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            order: 2,
                            object_name: "History",
                            label: '7 - History',
                            related: [
                                {
                                    order: 0,
                                    label: '8 - Revision',
                                    src: '/manage/function/Orders__Revisions_revisionDetailView/0?_mode=config&_format=json&_pk_id=2',
                                    related: [
                                        {
                                            order: 0,
                                            label: '9 - Line',
                                            src: '/manage/function/Orders__Revisions__Lines_lineDetailView/0?_mode=config&_format=json&_pk_id=2',
                                            related: [
                                                {
                                                    order: 0,
                                                    label: '10 - Element',
                                                    content: {
                                                        Description: 2,
                                                        Variant: 'Test Variant 1 (TEST01-SIL)',
                                                        Kind: 'Send',
                                                        Status: 'Shipped',
                                                        Price: 78.24,
                                                        'Declared VAT': 10.21,
                                                        Balance: 0.00,
                                                        'Pending Balance': 0.00
                                                    },
                                                    related: [
                                                        {
                                                            order: 0,
                                                            label: '11 - Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=6'
                                                        }
                                                    ]
                                                }
                                            ]
                                        }
                                    ]
                                },
                                {
                                    order: 1,
                                    label: '12 - Revision',
                                    src: '/manage/function/Orders__Revisions_revisionDetailView/0?_mode=config&_format=json&_pk_id=2',
                                    related: [
                                        {
                                            order: 0,
                                            label: '13 - Line',
                                            src: '/manage/function/Orders__Revisions__Lines_lineDetailView/0?_mode=config&_format=json&_pk_id=2',
                                            related: [
                                                {
                                                    order: 0,
                                                    label: '14 - Element',
                                                    content: {
                                                        Description: 2,
                                                        Variant: 'Test Variant 1 (TEST01-SIL)',
                                                        Kind: 'Send',
                                                        Status: 'Shipped',
                                                        Price: 78.24,
                                                        'Declared VAT': 10.21,
                                                        Balance: 0.00,
                                                        'Pending Balance': 0.00
                                                    },
                                                    related: [
                                                        {
                                                            order: 0,
                                                            label: '15 - Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=6'
                                                        },
                                                        {
                                                            order: 1,
                                                            label: '15a - Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=6'
                                                        }
                                                    ]
                                                },
                                                {
                                                    order: 1,
                                                    label: '16 - Element',
                                                    content: {
                                                        Description: 2,
                                                        Variant: 'Test Variant 1 (TEST01-SIL)',
                                                        Kind: 'Send',
                                                        Status: 'Shipped',
                                                        Price: 78.24,
                                                        'Declared VAT': 10.21,
                                                        Balance: 0.00,
                                                        'Pending Balance': 0.00
                                                    },
                                                    related: [
                                                        {
                                                            order: 0,
                                                            label: '17 - Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=6'
                                                        },
                                                        {
                                                            order: 1,
                                                            label: '17a - Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=6'
                                                        }

                                                    ]
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            order: 3,
                            label: '18 - Payments',
                            related: [
                                {
                                    order: 0,
                                    label: '19 - Transaction',
                                    src: '/manage/function/Transactions_txnDetailView/0?_mode=config&_format=json&_pk_id=122',
                                    content: {
                                        Description: 5,
                                        '# of Requests': 1
                                    },
                                    related: [
                                        {
                                            order: 0,
                                            label: '20 - Line',
                                            src: '/manage/function/TransactionAllocations__Lines_talDetailView/0?_mode=config&_format=json&_pk_id=1'
                                        },
                                        {
                                            order: 1,
                                            label: '21 - Line',
                                            src: '/manage/function/TransactionAllocations__Lines_talDetailView/0?_mode=config&_format=json&_pk_id=2'
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            order: 4,
                            label: '22 - Notes',
                            content: 'No notes recorded for this order yet.'
                        }
                    ]
                },

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
