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


/*
So what's actually going on here?
This module should manage an outer ManageTabView, 
and hosts a tab for (ex: order) the detail, revision 1, 2, 3..., transaction, goods, notes.
Then each tab's panel is an ManageActionTabView - 
a subclass of ManageTabView and contains a second level of inner tabs - 
but the tabs just look like links and simply hide/show panels.
Those inner panels are things like [the object], log, edit, (maybe new).
So when we look at an object detail (clicked from a datatable for example), 
we need metadata to set up the outer tabs.
Each inner tab can be loaded as needed from a JSON response,
but might as well pull it all down at once. 
meta_data = {
  tabs: [
    {
      tab_order: 0,
      tab_label: 'Detail',
      content: { 
        action_log: [...],
        auto_settings: [...],
        other_settings: [
          {
            field: "delivery_date_preferred",
            value: "2009-11-30",
            label: "Preferred Delivery Date",
            field_type: "date",
            required: true
          },
          ... // other fields
        ],
        ... // other things like pk_settings
      }
    },
    {
      tab_order: 1,
      tab_label: 'Current Revision',
      content: { 
        action_log: [...],
        auto_settings: [...],
        other_settings: [...],
        nested: [
          {
            tab_order: 0,
            tab_label: 'Line [7-13]',
            content: { 
              ...
              nested: [...]
            }
          }
        ]
      }
    },
    ... // etc
  ]
}
 */


YUI.add(
    "ic-manage-widget-function-detail",
    function(Y) {
        var ManageFunctionDetail;

        ManageFunctionDetail = function (config) {
            ManageFunctionDetail.superclass.constructor.apply(this, arguments);
        };

        ManageFunctionDetail.NAME = "ic_manage_function_detail";

        Y.extend(
            ManageFunctionDetail,
            Y.IC.ManageFunction,
            {
                /*
                 * For an Order, this is the structure: (treeview only for +1 objects)
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
                 *                     |        |          |
                 *                     v        |          |
                 *         (treeview) Line+[Elem|nt+[Parcel|ap]], Line, Line, ...
                 *                              |          |
                 *                              v          |
                 *                  (treeview) Transaction+|Allocation], Transaction, Transaction, ...
                 *                               |         |
                 *                               v         |
                 *                   (treeview) Line, Line,|Line...
                 *                                         |
                 *                                         v
                 *                             (treeview) Note, Note, Note
                 *
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
                            label: 'Details',
                            src: '/manage/function/Orders_orderDetailView/0?_mode=config&_format=json&_pk_id=6'
                        },
                        {
                            order: 1,
                            label: 'Goods',
                            related: [
                                {
                                    order: 0,
                                    label: 'Line',
                                    src: '/manage/function/Variants_variantDetailView/0?_mode=config&_format=json&_pk_id=1',
                                    related: [
                                        {
                                            order: 0,
                                            label: 'Inventory Map',
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
                                                    label: 'Inventory Record',
                                                    src: '/manage/function/Inventories_recordDetailView/0?_mode=config&_format=json&_pk_id=13'
                                                }
                                            ]
                                        },
                                        {
                                            order: 1,
                                            label: 'Inventory Map',
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
                                                    label: 'Inventory Record',
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
                            label: 'History',
                            related: [
                                {
                                    order: 0,
                                    label: 'Revision',
                                    src: '/manage/function/Orders__Revisions_revisionDetailView/0?_mode=config&_format=json&_pk_id=2',
                                    related: [
                                        {
                                            order: 0,
                                            label: 'Line',
                                            src: '/manage/function/Orders__Revisions__Lines_lineDetailView/0?_mode=config&_format=json&_pk_id=2',
                                            related: [
                                                {
                                                    order: 0,
                                                    label: 'Element',
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
                                                            label: 'Parcel',
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
                                    label: 'Revision',
                                    src: '/manage/function/Orders__Revisions_revisionDetailView/0?_mode=config&_format=json&_pk_id=8',
                                    related: [
                                        {
                                            order: 0,
                                            label: 'Line',
                                            src: '/manage/function/Orders__Revisions__Lines_lineDetailView/0?_mode=config&_format=json&_pk_id=14',
                                            related: [
                                                {
                                                    order: 0,
                                                    label: 'Element',
                                                    content: {
                                                        Description: 14,
                                                        Variant: 'Test Variant 1 (TEST01-SIL)',
                                                        Kind: 'Receive',
                                                        Status: 'Pending Return',
                                                        Price: -78.24,
                                                        'Declared VAT': -10.21,
                                                        Balance: -78.24,
                                                        'Pending Balance': -78.24,
                                                        Options: '[ Add Adjustment ]'
                                                    },
                                                    related: [
                                                        {
                                                            order: 0,
                                                            label: 'Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=18'
                                                        }
                                                    ]
                                                },
                                                {
                                                    order: 1,
                                                    label: 'Element',
                                                    content: {
                                                        Description: 15,
                                                        Variant: 'Test Variant 1 (TEST01-SIL)',
                                                        Kind: 'Send',
                                                        Status: 'Dynamic Sold',
                                                        Price: 78.24,
                                                        'Declared VAT': 11.65,
                                                        Balance: 78.24,
                                                        'Pending Balance': 78.24,
                                                        Options: '[ Add Adjustment ]'
                                                    },
                                                    related: [
                                                        {
                                                            order: 1,
                                                            label: 'Parcel',
                                                            src: '/manage/function/Parcels_parcelDetailView/0?_mode=config&_format=json&_pk_id=18'
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
                            label: 'Payments',
                            related: [
                                {
                                    order: 0,
                                    label: 'Transaction',
                                    src: '/manage/function/Transactions_txnDetailView/0?_mode=config&_format=json&_pk_id=122',
                                    content: {
                                        Description: 5,
                                        '# of Requests': 1
                                    },
                                    related: [
                                        {
                                            order: 0,
                                            label: 'Line',
                                            src: '/manage/function/TransactionAllocations__Lines_talDetailView/0?_mode=config&_format=json&_pk_id=1'
                                        },
                                        {
                                            order: 1,
                                            label: 'Line',
                                            src: '/manage/function/TransactionAllocations__Lines_talDetailView/0?_mode=config&_format=json&_pk_id=2'
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            order: 4,
                            label: 'Notes',
                            content: 'No notes recorded for this order yet.'
                        }
                    ]
                },


                _tabs: null,

                bindUI: function () {
                    this.on('visibleChange', Y.bind(this._onVisibleChange, this));
                },

                /*
                 * This should be broken up into a bunch of addTab()
                 * method calls.  And the forms should update the
                 * metadata, so listen for form successes and update
                 * the metadata, then redraw the tabs.  Also, make it
                 * state driven with eh HistoryManger - simply which
                 * tab is selected.
                 */
                _buildUI: function () {
                    Y.log('detail::_buildUI');

                    // the meta_data is already available, so build the outer tabs from it
                    this._meta_data = this._dummy_data; // testing...
                    var prefix = this.get('prefix') + '_ot';
                    this._tabs = new Y.IC.ManageTabView(
                        {
                            prefix: prefix
                        }
                    );
                    Y.each(this._meta_data.tabs, Y.bind(function (v, i) {
                        // Y.log('_meta_data.tab: ' + i);
                        if (!Y.Lang.isValue(v.src)) v['src'] = null;
                        if (!Y.Lang.isValue(v.related)) v['related'] = null;
                        // var content = this._buildContent(v.content);
                        /*
                        Y.log('v -> src -> related -> content');
                        Y.log(v);
                        Y.log(v.src);
                        Y.log(v.related);
                        Y.log(content);
                        */
                        this._tabs.add({
                            label: v.label, 
                            content: 'Loading...',
                            index: v.order,
                            plugins: [{
                                fn: Y.IC.ManageTabIO,
                                cfg: {
                                    uri: v.src || null,
                                    content: v.content || null,
                                    related: v.related || null
                                }
                            }] 
                        }, v.order);
                    }, this));
                    this._tabs.after('render', Y.bind(this._afterOuterTabsRender, this));
                    this._tabs.after('selectionChange', Y.bind(this._onSelectOuterTab, this));
                    this._content_node.setContent('');
                    this._tabs.render(this._content_node);
                    this.fire('manageFunction:loaded');
                },

                _updateOuterTabPanel: function (tab_index) {
                    Y.log('detail::_updateOuterTabPanel');
                    Y.log('...does nothing');
                },

                _buildContent: function (data) {
                    Y.log('detail::_buildContent');
                    Y.log(data);
                    if (Y.Lang.isString(data)) {
                        return data;
                    }
                    else if (Y.Lang.isObject(data)) {
                        var content = [];
                        if (Y.Lang.isValue(data.object_name)) {
                            content.push('<h3>' + data.object_name + '</h3>');
                        }
                        if (Y.Lang.isValue(data.pk_settings)) {
                            content.push(data.pk_settings[0].field + ": " + data.pk_settings[0].value);
                        }
                        if (Y.Lang.isValue(data.other_settings)) {
                            content.push("<br /><br />");
                            for (i = 0; i < data.other_settings.length; i += 1) {
                                row = data.other_settings[i];
                                content.push(row.field + ": " + row.value + "<br />");
                            }
                        }
                        return content.join('');
                    }
                    else if (Y.Lang.isUndefined(data)) {
                        return 'empty';
                    }
                },

                _buildActionLog: function (data, actions) {
                    if (Y.Lang.isValue(data.action_log)) {
                        var content = [];
                        content.push('<div style="text-align: left; font-size: 130%; font-weight: bold;">Log</div>');
                        content.push('<table>');
                        for (i = 0; i < data.action_log.length; i += 1) {
                            row = data.action_log[i];
                            
                            content.push('<tr>');
                            content.push('<td>' + row.label + '</td>');
                            content.push('<td>');
                            if (row.details.length > 0) {
                                for (j = 0; j < row.details.length; j += 1) {
                                    content.push(row.details[j] + "<br />");
                                }
                            }
                            content.push('</td>');
                            content.push('<td>' + row.date_created + '</td>');
                            content.push('<td>' + row.content + '</td>');
                            content.push('</tr>')
                        }
                        content.push('<table>');

                        // add a tab to the actions panel
                        actions.add({
                            label: 'View Log', 
                            content: content.join(''),
                            index: actions.length
                        });
                    }
                },

                _onSelectOuterTab: function (e) {
                    Y.log('detail::_onSelectOuterTab');
                    Y.log('panel text: ' + e.newVal.get('panelNode').get('text'));
                    // Y.log(e.newVal.get('index'));
                    // this._updateOuterTabPanel(e.newVal.get('index'));
                },

                _afterOuterTabsRender: function (e) {
                    Y.log('detail::_afterOuterTabsRender');
                    // Y.log(e.target); // tabview
                    e.target.selectChild(Number(e.target.get('state.st')));
                },

                renderForm: function (e) {
                    // Y.log('detail::onTabviewRender');
                    // var tab = e.target._items[this._tab_indices['edit']];
                    var panel = this._tabs.getPanel('Edit');

                    var fields = [];
                    if (Y.Lang.isValue(this._meta_data.other_settings)) {
                        var i;
                        for (i = 0; i < this._meta_data.other_settings.length; i += 1) {
                            row = this._meta_data.other_settings[i];
                            fields[i] = {
                                name: row.field, 
                                label: row.field, 
                                value: row.value ? row.value.toString() : ''
                            };
                        }
                        fields[i] = {type : 'submit', label : 'Submit'};
                        fields[++i] = {type : 'reset', label : 'Reset'};
                    }


                    var f = new Y.Form({
                        action : '/manage/index', // should be a nice long load...
                        method : 'post',
                        fields : fields
                    });
 
                    f.subscribe('success', function (args) {
                        Y.log('Form submission successful');
                    });
                    f.subscribe('failure', function (args) {
                        Y.log('Form submission failed');
                    });

                    f.render(panel);
                },

                getHeaderText: function () {
                    if (this._meta_data) {
                        var pks = this._meta_data.pk_settings[0];
                        var value = pks.value;
                        var header = this._meta_data.object_name + ' Detail ' + value;
                        // Y.log('detail::getHeaderText - header: ' + header);
                        return header;
                    }
                    else {
                        // Y.log('detail::getHeaderText - header is null - no meta_data');
                        return null;
                    }
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
            "gallery-form",
            "ic-manage-widget-tabview",
            "ic-manage-plugin-tabio"
        ]
    }
);
