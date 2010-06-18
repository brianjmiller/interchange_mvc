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
    "ic-manage-widget-tabview",
    function(Y) {
        var ManageTabView = Y.Base.create (
            "ic_manage_widget_tabview",
            Y.TabView,
            [Y.IC.HistoryManager],
            {
                STATE_PROPERTIES: {
                    'st': 1  // selected-tab, stores tab index
                },

                _tabs: {},

                initializer: function (config) {
                    ManageTabView.superclass.initializer.apply(this, arguments);
                    this.after('addChild', Y.bind(this._afterAddChild, this));
                    this.after('selectionChange', Y.bind(this._myAfterSelectionChange, this));
                    this.after('stateChange', Y.bind(this._afterStateChange, this));
                    if (!this._on_history_change) {
                        this._on_history_change = Y.on(
                            'history-lite:change', 
                            Y.bind(this._onHistoryChange, this)
                        );
                    }
                    // capture the tab clicks
                    Y.delegate(
                        "click",
                        this._onTabClick,
                        this.get("boundingBox"),
                        'li.yui3-tab',
                        this
                    );

                    this.set('state', this.getRelaventHistory());
                },

                destructor: function () {
                    this._tabs = null;
                    ManageTabView.superclass.destructor.apply(this, arguments);
                },

                getTabByLabel: function (label) {
                    // Y.log('tabview::getTabByLabel');
                    var tab = null;
                    Y.each(this._tabs, function (v, k, obj) {
                        if (v.label === label) tab = v.tab;
                    });
                    return tab;
                },

                getPanelByLabel: function (label) {
                    // Y.log('tabview::getPanelByLabel');
                    var tab = this.getTabByLabel(label);
                    if (tab) return tab.get('panelNode');
                },

                getTabByIndex: function (index) {
                    // Y.log('tabview::getTabByIndex');
                    var tab = null;
                    Y.each(this._tabs, function (v, k, obj) {
                        if (v.index === index) tab = v.tab;
                    });
                    return tab;
                },

                getPanelByIndex: function (index) {
                    // Y.log('tabview::getPanelByIndex');
                    var tab = this.getTabByIndex(index);
                    if (tab) {
                        return tab.get('panelNode');
                    }
                },

                selectTabByLabel: function (label) {
                    // Y.log('tabview::selectTabByLabel');
                    if (this.get('selection')) {
                        if (this.get('selection').get('label') !== label) {
                            Y.each(this._tabs, function (v, k, obj) {
                                if (v.label === label) this.selectChild(v.index);
                            });
                        }
                    }
                },

                selectTabByIndex: function (index) {
                    // Y.log('tabview::selectTabByIndex - index: ' + index);
                    if (this.get('selection')) {
                        index = Number(index);
                        if (this.get('selection').get('index') !== index) {
                            this.selectChild(index);
                        }
                    }
                },

                getTab: function (key) {
                    // Y.log('tabview::getTab');
                    if (typeof key === 'string') {
                        return this.getTabByLabel(key);
                    }
                    else if (typeof ley === 'number') {
                        return this.getTabByIndex(key);
                    }
                    else {
                        Y.error("ManageTabView.getTab(key): 'key' must be a number or string.");
                    }
                },

                getPanel: function (key) {
                    // Y.log('tabview::getPanel');
                    if (typeof key === 'string') {
                        return this.getPanelByLabel(key);
                    }
                    else if (typeof ley === 'number') {
                        return this.getPanelByIndex(key);
                    }
                    else {
                        Y.error("ManageTabView.getPanel(key): 'key' must be a number or string.");
                    }
                },

                selectTab: function (key) {
                    // Y.log('tabview::selectTab');
                    if (typeof key === 'string') {
                        return this.selectTabByLabel(key);
                    }
                    else if (typeof ley === 'number') {
                        return this.selectTabByIndex(key);
                    }
                    else {
                        Y.error("ManageTabView.selectTab(key): 'key' must be a number or string.");
                    }
                },

                _setDefSelection: function(contentBox) {
                    // Y.log('tabview::_setDefSelection');
                    var st = this.get('state.st') || 0;

                    //  If no tab is selected, select by state.
                    var selection = this.get('selection') || this.item(Number(st));

                    this.some(function(tab) {
                        if (tab.get('selected')) {
                            selection = tab;
                            return true;
                        }
                    });

                    if (selection) {
                        selection.set('selected', 1);
                    }
                },

                _afterAddChild: function (e) {
                    // Y.log('tabview::_afterAddChild');
                    // keep an object with references to each child
                    // e.child e.index e.child.get('label')
                    this._tabs[e.index] = {
                        tab: e.child,
                        label: e.child.get('label'),
                        index: e.index
                    };
                },

                _afterStateChange: function (e) {
                    // Y.log('tabview::_afterStateChange - prefix: ' + this.get('prefix'));
                    var state = this.get('state.st');
                    // Y.log('state.st: ' + state);
                    if (state) {
                        this.selectTabByIndex(state);
                    }
                },

                _myAfterSelectionChange: function (e) {
                    // Y.log('tabview::_afterSelectionChange - st: ' + e.newVal.get('index'));
                    // only update the history if i have state
                    var state = {st: e.newVal.get('index')};
                    Y.HistoryLite.add(this._addMyHistoryPrefix(state));
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageTabView = ManageTabView;
    },
    "@VERSION@",
    {
        requires: [
            "ic-history-manager",
            "base-base",
            "tabview"
        ]
    }
);
