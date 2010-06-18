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
                _tabs: null,

                bindUI: function () {
                    // why doesn't this work?
                    // Y.on('tabView:render', Y.bind(this.onTabviewRender, this));
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
                    // Y.log('detail::_buildUI');
                    // first i should build th tabs, with empty panels
                    // then on render, set the tab panel contents.
                    // so how to i get the tab configuration?
                    
                    // also, set up 
                    // Y.after.('selectionChange', Y.bind(this._afterSelectionChange, this)) 
                    // to update state/history

                    // and fix the tabView:render event

                    var row = null,
                        action_log_tab_index = null,
                        action_log_tab_content = ""
                    ;

                    var contentBox = this._content_node;
                    var data = this._meta_data;

                    contentBox.setContent('<div style="text-align: left; font-size: 110%;">' + data.object_name + '</div>');

                    var tab_config_children = [
                        {
                            label: "Details",
                        }
                    ];

                    tab_config_children[0].content = data.pk_settings[0].field + ": " + data.pk_settings[0].value;

                    if (Y.Lang.isValue(data.other_settings)) {
                        tab_config_children[0].content += "<br /><br />";
                        for (i = 0; i < data.other_settings.length; i += 1) {
                            row = data.other_settings[i];

                            tab_config_children[0].content += row.field + ": " + row.value + "<br />";
                        }
                    }

                    if (Y.Lang.isValue(data.action_log)) {
                        action_log_tab_index = tab_config_children.push(
                            {
                                label: "Log"
                            }
                        );

                        action_log_tab_content += '<div style="text-align: left; font-size: 130%; font-weight: bold;">Log</div>';
                        action_log_tab_content += '<table>';
                        for (i = 0; i < data.action_log.length; i += 1) {
                            row = data.action_log[i];

                            action_log_tab_content += '<tr>'
                            action_log_tab_content += '<td>' + row.label + '</td>';
                            action_log_tab_content += '<td>';
                            if (row.details.length > 0) {
                                for (j = 0; j < row.details.length; j += 1) {
                                    action_log_tab_content += row.details[j] + "<br />";
                                }
                            }
                            action_log_tab_content += '</td>';
                            action_log_tab_content += '<td>' + row.date_created + '</td>';
                            action_log_tab_content += '<td>' + row.content + '</td>';
                            action_log_tab_content += '</tr>'
                        }
                        action_log_tab_content += '<table>';

                        tab_config_children[action_log_tab_index - 1].content = action_log_tab_content;
                    }

                    // do the form tab
                    var form_tab_index = tab_config_children.push(
                        {
                            label: "Edit"
                        }
                    );

                    var prefix = this.get('prefix') + '_ot';
                    this._tabs = new Y.IC.ManageTabView(
                        {
                            children: tab_config_children,
                            prefix: prefix // outer tabs
                        }
                    );

                    this._tabs.after('render', Y.bind(this.onTabviewRender, this));
                    this._tabs.render(contentBox);

                    this.fire('manageFunction:loaded');
                },

                onTabviewRender: function (e) {
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
            "ic-manage-widget-tabview"
        ]
    }
);
