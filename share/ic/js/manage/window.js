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
    "ic-manage-window",
    function (Y) {

        var ManageWindow = Y.Base.create (
            "ic_manage_window",     // module identifier  
            Y.Base,                 // what to extend     
            [Y.IC.HistoryManager],  // classes to mix in  
            {                       // overrides/additions
                // Instance Members //

                // i'm using the following as a sort of cache
                //  - should probably wrap them up into an object
                // these first for are for the widgets
                _menu:            null,
                _dt_container:    null,
                _dv_container:    null,
                _dash:            null,

                // and here's a "cache" for the dom nodes that contain
                // the above widgets
                _div_cache:       {},

                // a saved callback to be executed when 
                //  the center layout (which is dynamic) 
                //  has rendered
                _center_layout_onrender_callback:   null,

                // dealing with three layouts, one outer and two inner
                //  (we may add more...)
                _layouts: {
                    'outer':  null,
                    'left':   null,
                    'center': null
                },

                STATE_PROPERTIES: {
                    'lc': 1  /*
                              * layout-center, possible values:
                              *  lc: 'maxdv' // max center unit
                              *  lc: 'maxdt' // max top unit
                              *  lc: 'dtdv'  // top at 152
                              */
                },

                // Base Methods //
                initializer: function (config) {
                    // Y.log('window::initializer');

                    this.after('stateChange', this._afterStateChange);
                    Y.on('history-lite:change', Y.bind(this._onHistoryChange, this));

                    this.set('state', this.getRelaventHistory());

                    // listen for widget loaded events 
                    //  and decorate our layout to match the contents
                    Y.on("manageContainer:widgetshown", this.updateHeaderText);
                    Y.on("manageContainer:widgetmetadata", this.updateHeaderText);
                },

                // called by _afterStateChange
                initOuterLayout: function (lc) {
                    // Y.log('window::initOuterLayout');
                    // build the main layout
                    this.buildOuterLayout('outer');
                    this._layouts['outer'].on(
                        'render', 
                        Y.bind(this.onOuterLayoutRender, this, lc)
                    );
                    this._layouts['outer'].render();
                },

                // the main layout
                buildOuterLayout: function (key) {
                    // Y.log('window::buildOuterLayout');
                    var YAHOO = Y.YUI2;
                    this._layouts[key] = new YAHOO.widget.Layout(
                        {
                            units: [
                                {
                                    position: "top",
                                    height: 26,
                                    zIndex: 0,
                                    body: "manage_header"
                                },
                                {
                                    position: "left",
                                    body: "manage_subcontainer",
                                    width: 170,
                                    zIndex: 1
                                },
                                {
                                    position: "center",
                                    zIndex: 0,
                                    scroll: false
                                },
                                {
                                    position: "bottom",
                                    body: "manage_footer",
                                    zIndex: 0,
                                    height: 40,
                                    resize: true
                                }
                            ]
                        }
                    );
                },

                // an inner layout - contains the main menu and quick links
                buildLeftLayout: function (layout, unit, key) {
                    // Y.log('window::buildLeftLayout');
                    var YAHOO = Y.YUI2;
                    var left = layout.getUnitByPosition(unit).get("wrap");
                    this._layouts[key] = new YAHOO.widget.Layout(
                        left,
                        {
                            parent: layout,
                            units: [
                                {
                                    position: "top",
                                    body: "manage_menu",
                                    header: "Main Menu",
                                    height: 212,
                                    zIndex: 2,
                                    scroll: null
                                },
                                {
                                    position: "center",
                                    body: "manage_quick",
                                    header: "Quick Links",
                                    zIndex: 0
                                }
                            ]
                        }
                    );
                },

                /*
                 *  DTDV = Datatable / Detail View - top and center
                 *  units. Gets the height of the top unit from the
                 *  version param.  The param should be a valid state
                 *  property ('dtmax', 'dvmax', dtdv').
                 */
                buildDTDVLayout: function (layout, unit, key, version) {
                    // Y.log('window::buildDTDVLayout - version: ' + version);

                    var YAHOO = Y.YUI2;
                    var center = layout.getUnitByPosition(unit).get("wrap");
                    var body = Y.one(document.body);
                    var height = 152;
                    switch (version) {
                    case 'dtmax':
                        height = Y.DOM.region(center).height;  // used to initially render the top
                                                               // unit to the max available height
                                                               // effectively hiding the detail view
                        break;
                    case 'dvmax':
                        height = 0;
                    case 'dtdv':
                    default:
                        height = 152;
                        break;
                    }

                    this.saveMyContainers();

                    // then build the layout
                    var new_layout = new YAHOO.widget.Layout(
                        center,
                        {
                            parent: layout,
                            units: [
                                {
                                    position: "top",
                                    body: "manage_datatable",
                                    header: "Records",
                                    height: height,
                                    zIndex: 0,
                                    collapse: true,
                                    animate: false,
                                    scroll: false
                                },
                                {
                                    position: "center",
                                    body: "manage_detail",
                                    header: "Details",
                                    zIndex: 0,
                                    scroll: true
                                }

                            ]
                        }
                    );
                    this.destroyExtraLayoutElements(key);
                    this._layouts[key] = new_layout;
                    Y.HistoryLite.add(this._addMyHistoryPrefix({lc: version}));
                },

                /*
                 *  Dashboard - currently a single unit.  It isn't
                 *  hard to imagine that the dashboard will become
                 *  more complex, so it's nice for it to have it's own
                 *  layout possibilities.
                 */
                buildDashLayout: function (layout, unit, key) {
                    // Y.log('window::buildDashLayout');
                    var YAHOO = Y.YUI2;
                    var center = layout.getUnitByPosition(unit).get("wrap");

                    this.saveMyContainers();

                    // then build the layout
                    var new_layout = new YAHOO.widget.Layout(
                        center,
                        {
                            parent: layout,
                            units: [
                                {
                                    position: "center",
                                    body: "manage_dashboard",
                                    header: "Dashboard",
                                    zIndex: 0,
                                    scroll: true
                                }
                                // add more units as required
                            ]
                        }
                    );
                    this.destroyExtraLayoutElements(key);
                    this._layouts[key] = new_layout;
                    Y.HistoryLite.add(this._addMyHistoryPrefix({lc: 'dash'}));
                },

                onOuterLayoutRender: function (center_layout) {
                    // Y.log('window::onOuterLayoutRender');
                    this._layouts['outer'].removeListener('render');

                    var buildCenterLayout, onCenterLayoutRender;

                    if (center_layout === 'dash') {
                        buildCenterLayout = this.buildDashLayout;
                        onCenterLayoutRender = Y.bind(this.onDashLayoutRender, this);
                    }
                    else {
                        buildCenterLayout = this.buildDTDVLayout;
                        onCenterLayoutRender = Y.bind(this.onDTDVLayoutRender, this);
                    }

                    Y.bind(
                        this.buildLeftLayout,
                        this,                     // context
                        this._layouts['outer'],   // parent layout
                        'left',                   // unit
                        'left'                    // new layout key
                    )();
                    Y.bind(
                        buildCenterLayout, 
                        this,                     // context
                        this._layouts['outer'],   // parent layout
                        'center',                 // unit
                        'center',                 // new layout key
                        center_layout
                    )();

                    this._layouts['left'].on(
                        'render', 
                        Y.bind(this.onLeftLayoutRender, this)
                    );
                    this._layouts['center'].on(
                        'render', 
                        onCenterLayoutRender
                    );

                    this._layouts['left'].render();
                    this._layouts['center'].render();
                },

                onLeftLayoutRender: function () {
                    // Y.log('window::onLeftLayoutRender');
                    this._layouts['left'].removeListener('render');
                    Y.bind(
                        this.initMainMenu, 
                        this,                   // context
                        this._layouts['left'],  // layout 
                        'top',                  // unit
                        'vertical'              // menu orientation
                    )();
                },

                restoreContainerFromCache: function (id, layout, unit_label) {
                    var tmp = Y.one('#' + id);
                    if (tmp) {
                        tmp.replace(this._div_cache[id]);
                    }
                    else {
                        var body = Y.one(layout.getUnitByPosition(unit_label).body);
                        body.setContent('');
                        body.append(this._div_cache[id]);
                    }
                    this._div_cache[id] = null;
                },

                onDTDVLayoutRender: function () {
                    // Y.log('window::onDTDVLayoutRender');
                    var layout = this._layouts['center'];
                    layout.removeListener('render');

                    // restore our containers
                    if (this._div_cache['manage_datatable']) {
                        this.restoreContainerFromCache(
                            'manage_datatable', layout, 'top'
                        );
                    }
                    if (this._div_cache['manage_detail']) {
                        this.restoreContainerFromCache(
                            'manage_detail', layout, 'center'
                        );
                    }

                    // update container layout info - this needs factored out...
                    if (this._dt_container) {
                        var unit = layout.getUnitByPosition('top');
                        this._dt_container.set('layout', layout);
                        this._dt_container.set('layout_unit', unit);
                    }
                    if (this._dv_container) {
                        var unit = layout.getUnitByPosition('center');
                        this._dv_container.set('layout', layout);
                        this._dv_container.set('layout_unit', unit);
                    }

                    // widgets are loaded from the history of the containers
                    this.executeSubmenuCallback();
                },

                onDashLayoutRender: function () {
                    // Y.log('window::onDashLayoutRender');
                    var layout = this._layouts['center'];
                    layout.removeListener('render');

                    if (! this._dash) {
                        Y.bind(
                            this.initDashboard, 
                            this,                     // context
                            this._layouts['center'],  // layout 
                            'center'                  // unit   
                        )();
                    }
                    else {
                        // restore the container
                        if (this._div_cache['manage_dashboard']) {
                            this.restoreContainerFromCache(
                                'manage_dashboard', layout, 'center'
                            );
                        }
                        this._dash.show();
                    }
                    this.executeSubmenuCallback();
                },

                initMainMenu: function (layout, unit, orientation) {
                    // Y.log('window::initMainMenu');
                    var menu_unit = layout.getUnitByPosition(unit).body.childNodes[0];
                    this._menu = new Y.IC.ManageMenu(
                        {
                            orientation: orientation,
                            render_to: menu_unit
                        }
                    );

                    // need to let the nodemenu's dropdowns spill into the the next unit
                    var cbody = Y.one(layout.getUnitByPosition(unit).body);
                    cbody.addClass('allow-overflow');
                    Y.one(cbody._node.parentNode.parentNode.parentNode).addClass('allow-overflow');

                    // capture the menu events
                    Y.delegate(
                        "mousedown",
                        this.onSubmenuMousedown,
                        this._menu.get("boundingBox"),
                        'em.yui3-menuitem-content',
                        this
                    );
                    Y.delegate(
                        "mousedown",
                        this.onSubmenuMousedown,
                        this._menu.get("boundingBox"),
                        'a.yui3-menuitem-content',
                        this
                    );
                },

                /* 
                 *  Build the dashboard.  this is primative.
                 *  eventually we'll likely want a more complex layout
                 *  for the dashboard, and may load several widgets
                 *  into it.
                 */ 
                initDashboard: function (layout, unit) {
                    // Y.log('window::initDashboard');
                    var center = layout.getUnitByPosition(unit);
                    var dash_div = this.initContainerDiv('manage_dashboard', unit);
                    this._dash = new Y.IC.ManageDashboard();
                    this._dash.render(dash_div);
                },

                executeSubmenuCallback: function () {
                    if (this._center_layout_onrender_callback) {
                        this._center_layout_onrender_callback();
                        this._center_layout_onrender_callback = null;
                    }
                },

                onSubmenuMousedown: function (e) {
                    // Y.log('window::onSubmenuMousedown');

                    // hide the submenu after a selection -- there
                    // seems to be a selection bug in here - should
                    // also clear the selection...
                    menu_nav_node = this._menu.get("boundingBox")
                    var menuNav = menu_nav_node.menuNav;
                    menuNav._hideAllSubmenus(menu_nav_node);

                    if (this.get('state.lc') !== 'dtmax') {
                        // save a callback because the layout needs to be built/rendered first
                        this._center_layout_onrender_callback = Y.bind(this.doSubmenuRequest, this, e);
                        Y.HistoryLite.add(this._addMyHistoryPrefix({lc: 'dtmax'}));
                    }
                    else {
                        this.doSubmenuRequest(e);
                    }

                    // i need to determine if i've selected a list or an add or the dash
                    //  currently i assume every item should render a list...
                },

                doSubmenuRequest: function (e) {
                    // Y.log('window::doSubmenuRequest');
                    var center = this._layouts['outer'].getUnitByPosition("center").get("wrap");
                    var top = this._layouts['center'].getUnitByPosition("top");

                    // if there's no datatable container, create one
                    if (!this._dt_container) {
                        var dt_div = this.initContainerDiv('manage_datatable', top);
                        this._dt_container = new Y.IC.ManageContainer(
                            {
                                render_to: dt_div,
                                prefix: '_dt',
                                layout: this._layouts['center'],
                                layout_unit: top
                            }
                        );
                    }

                    // load the Widget into the Data Table container
                    Y.bind(this._dt_container.loadWidget, this._dt_container)(e);

                    // capture clicks on the "detail" link of the option column
                    Y.delegate(
                        "click",
                        this.onDetailClick,
                        center,
                        'a.manage_function_link',
                        this
                    );
                },

                /*
                 * Currently, it is assumed that detail links are only
                 * in the datatables.  If/when that changes, this may
                 * also have to change.
                 *
                 * Loads a inner layout with a short datatable and
                 * large detail view.
                 */
                onDetailClick: function (e) {
                    // Y.log('window::onDetailClick');
                    if (this.get('state.lc') !== 'dtdv') {
                        Y.HistoryLite.add(this._addMyHistoryPrefix({lc: 'dtdv'}));
                        // save a callback, because the layout needs to be built/rendered first
                        this._center_layout_onrender_callback = Y.bind(this.doDetailRequest, this, e);
                    }
                    else {
                        this.doDetailRequest(e);
                    }
                },

                getOrCreateNodeById: function (id) {
                    var div = Y.one('#' + id);
                    if (!div) {
                        var app_container = Y.one('#ic-manage-app-container');
                        app_container.append(Y.Node.create('<div id="' + id + '"></div>'));
                        div = Y.one('#' + id);
                    }
                    return div;
                },

                initContainerDiv: function (id, unit) {
                    var div = Y.one('#' + id);
                    if (!div) {
                        var unit_body = Y.one(unit.body);
                        unit_body.setContent('');
                        unit_body.append('<div id="' + id + '"></div>');
                        div = Y.one('#' + id);
                    }
                    return div;
                },

                doDetailRequest: function (e) {
                    // Y.log('window::doDetailRequest');
                    var top = this._layouts['center'].getUnitByPosition("top");
                    var center = this._layouts['center'].getUnitByPosition("center");

                    // shrink the top unit and show only 3 rows in the datatable, 
                    //  making room for the detail view without closing the datatable
                    top.set('height', 152);

                    if (this._dt_container) {
                        var dt = this._dt_container.get('current');
                        top.set('header', dt.getHeaderText());
                        var YAHOO = Y.YUI2;
                        if (dt instanceof Y.IC.ManageFunctionExpandableList) {
                            Y.log('shrink the datatable to 3 rows')
                            // ... need some stuffs here
                        }
                    }

                    // if there's no detail view container, create one
                    if (!this._dv_container) {
                        var dv_div = this.initContainerDiv('manage_detail', center);
                        // no detail view container
                        this._dv_container = new Y.IC.ManageContainer(
                            {
                                render_to: dv_div,
                                prefix: '_dv',
                                layout: this._layouts['center'],
                                layout_unit: center
                            }
                        );
                    }
                    else {
                        Y.log('detail view container already exists');
                    }

                    // load the Widget into the Detail View container
                    Y.bind(this._dv_container.loadWidget, this._dv_container)(e);

                    // capture clicks on the tabs of the detail view
                    /*
                    Y.delegate(
                        "click",
                        onTabPanelClick,
                        center,
                        'div.yui3-tab-panel'
                    );
                    */
                },

                /*
                 * the inner center layout get's rebuilt frequently,
                 * causing some dom destruction so in order not to
                 * lose our containers (and their cache), we save a
                 * reference to their dom nodes.
                 */
                saveMyContainers: function () {
                    Y.log('window::saveMyContainers');
                    // save our containers, and add any that are missing
                    var app_container = Y.one('#ic-manage-app-container');
                    var createOrSaveContainer = function (id, cache) {
                        var empty = '<div id="' + id + '"></div>';
                        var div = Y.one('#' + id);
                        if (!div) {
                            app_container.append(Y.Node.create(empty));
                        }
                        else if (div.hasChildNodes()) {
                            var tmp = Y.Node.create(empty);
                            cache[id] = div.get('parentNode').replaceChild(tmp, div); 
                        }
                    };

                    if (this._dt_container) {
                        createOrSaveContainer('manage_datatable', this._div_cache);
                    }
                    if (this._dv_container) {
                        createOrSaveContainer('manage_detail', this._div_cache);
                    }
                    if (this._dash) {
                        createOrSaveContainer('manage_dashboard', this._div_cache);
                    }
                },

                
                /*
                 * the Layout Manager was having some trouble with
                 * dynamic inner layouts, leaving extra dom nodes all
                 * over the place.  so this is a cleanup method to
                 * destroy any dom left over from a previous inner
                 * layout.
                 */
                destroyExtraLayoutElements: function (key) {
                    Y.log('window::destroyExtraLayoutElements');
                    // destroy any lingering elements from an existing layout
                    if (this._layouts[key]) {
                        Y.each(this._layouts[key]._units, function (v, k, obj) {
                            var id = obj[k].get('id');
                            var node = Y.one('#' + id);
                            if (node) {
                                node.remove();
                                node.destroy(true);
                            }
                        });
                    }
                },

                /*
                 * Some layout units have headers.  When they do, we
                 * want to get the header text from the widgets
                 * contained in the unit.
                 */
                updateHeaderText: function (e) {
                    // Y.log('window::updateHeaderText');
                    var container = e.target;
                    var widget = container.get('current');
                    var layout_unit = container.get('layout_unit');
                    if (widget && widget.getHeaderText && (widget.getHeaderText() !== null)) {
                        layout_unit.set('header', widget.getHeaderText());
                    }
                },

                /*
                 * Keeps track of our current layout state and
                 * initiates redraws when there's a change.  this
                 * allows us to draw a layout according to the browser
                 * history.
                 */
                _afterStateChange: function (e) {
                    // Y.log('window::_afterStateChange');
                    var state = this.get('state');
                    if (state.lc === undefined) {
                        this.initOuterLayout('dash');
                    }
                    else {
                        if ( ! this._layouts['outer'] ) {
                            this.buildOuterLayout('outer');
                            this._layouts['outer'].on(
                                'render', 
                                Y.bind(this.onOuterLayoutRender, this, state.lc)
                            );
                            this._layouts['outer'].render();
                        }
                        else {
                            var buildCenterLayout, onCenterLayoutRender;
                            if (state.lc === 'dash') {
                                buildCenterLayout = this.buildDashLayout;
                                onCenterLayoutRender = this.onDashLayoutRender;
                            }
                            else {
                                buildCenterLayout = this.buildDTDVLayout;
                                onCenterLayoutRender = this.onDTDVLayoutRender;
                            }
                            // destroy/build the center layout,
                            Y.bind(
                                buildCenterLayout,
                                this,
                                this._layouts['outer'],   // parent layout
                                'center',                 // unit
                                'center',                 // new layout key
                                state.lc                  // version
                            )();
                            this._layouts['center'].on(
                                'render', 
                                Y.bind(onCenterLayoutRender, this)
                            );
                            this._layouts['center'].render();
                        }
                    }
                },

                destructor: function () {
                    // Y.log('window::destructor');
                    this._menu.destroy();
                    this._menu = null;
                    this._dash.destroy();
                    this._dash = null;
                    this._dt_container.destroy();
                    this._dt_container = null;
                    this._dt_container.destroy();
                    this._dv_container = null;
                    this._div_cache = null;
                    this._layouts['left'].destroy();
                    this._layouts['center'].destroy();
                    this._layouts['outer'].destroy();
                    this._layouts['left'] = null;
                    this._layouts['center'] = null;
                    this._layouts['outer'] = null;
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageWindow = ManageWindow;
    },
    "@VERSION@",
    {
        requires: [
            "base-base",
            "ic-manage-widget-container",
            "ic-manage-widget-menu",
            "ic-manage-widget-dashboard",
            "ic-history-manager",
            "yui2-layout",
            "yui2-resize",
            "yui2-animation"
        ]
    }
);
