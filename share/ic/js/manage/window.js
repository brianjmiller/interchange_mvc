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

                // i'm using the following as a sort of cache.
                // these first for are for the widget containers
                _containers: {
                    'menu': null,
                    'dt': null,
                    'dv': null,
                    'dash': null
                },

                // and here's a cache for the dom nodes that contain
                // the above widget containers
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
                    Y.on(
                        'history-lite:change', 
                        Y.bind(this._onHistoryChange, this)
                    );
                    var rh = this.getRelaventHistory();
                    if (!rh.lc) rh = {lc: 'dash'};
                    this.set('state', rh);

                    // listen for widget loaded events 
                    //  and decorate our layout to match the contents
                    Y.on("manageFunctionList:tablerendered", 
                         Y.bind(this.onCheckFitness, this));
                    Y.on("manageFunctionList:tablerendered", 
                         Y.bind(this._listenToTheList, this));
                    Y.on("manageFunctionDetail:tabsrendered", 
                         Y.bind(this._fitDetailViewToUnit, this));
                },

                destructor: function () {
                    // Y.log('window::destructor');
                    Y.each(this._containers, function (v, k, obj) {
                        v.destroy();
                        v = null;
                        delete obj[k];
                    });
                    Y.each(this._layouts, function (v, k, obj) {
                        v.destroy();
                        v = null;
                        delete obj[k];
                    });
                    this._containers = null;
                    this._div_cache = null;
                    this._layouts = null;
                    // TODO also detach any event handlers ...
                },

                /*
                 * Some layout units have headers.  When they do, we
                 * want to get the header text from the widgets
                 * contained in the unit.
                 */
                updateHeaderText: function (e) {
                    // Y.log('window::updateHeaderText - widget');
                    var container = e.target;
                    var widget = container.get('current');
                    var layout_unit = container.get('layout_unit');
                    // Y.log(widget);
                    if (widget && widget.getHeaderText && 
                        (widget.getHeaderText() !== null)) {
                        layout_unit.set('header', widget.getHeaderText());
                    }
                },

                clearHeaderText: function (e) {
                    // Y.log('window::clearHeaderText');
                    var container = e.target;
                    var layout_unit = container.get('layout_unit');
                    layout_unit.set('header', '&nbsp;');
                },

                _setCollapsedHeader: function (e, o) {
                    // Y.log('window::_setCollapsedHeader');
                    var unit = o.layout.getUnitByPosition(o.unit);
                    var clip = Y.one(unit._clip);
                    if (!Y.one('span.clip-header')) {
                        clip.append(
                            '<span class="clip-header">Click to expand ' + 
                                o.expand_what + '.</span>'
                        );
                    }
                },

                // called by _afterStateChange
                _initOuterLayout: function (lc) {
                    // Y.log('window::_initOuterLayout');
                    // build the main layout
                    this._buildOuterLayout('outer');
                    this._layouts['outer'].on(
                        'render', 
                        Y.bind(this._onOuterLayoutRender, this, lc)
                    );
                    this._layouts['outer'].render();
                },

                // the main layout
                _buildOuterLayout: function (key) {
                    // Y.log('window::_buildOuterLayout');
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
                                    height: 32,
                                    resize: false
                                }
                            ]
                        }
                    );
                },

                // an inner layout - contains the main menu and quick links
                _buildLeftLayout: function (layout, unit, key) {
                    // Y.log('window::_buildLeftLayout');
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
                                    height: 210,
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
                _buildDTDVLayout: function (layout, unit, key, version) {
                    // Y.log('window::_buildDTDVLayout - version: ' + version);

                    var YAHOO = Y.YUI2;
                    var center = layout.getUnitByPosition(unit).get("wrap");
                    var body = Y.one(document.body);
                    var height = 150;
                    var resize = false;

                    switch (version) {
                    case 'dtmax':
                        height = Y.DOM.region(center).height;  // used to initially render the top
                                                               // unit to the max available height
                                                               // effectively hiding the detail view
                        this._clearContainer(['dv', 'dash']);
                        break;
                    case 'dvmax':
                        height = 0;
                        this._clearContainer(['dt', 'dash']);
                        break;
                    case 'dtdv':
                    default:
                        height = 150;
                        resize = true;
                        this._clearContainer(['dash']);
                        break;
                    }

                    this._saveMyContainers();

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
                                    minHeight: 108,
                                    zIndex: 0,
                                    collapse: true,
                                    resize: resize,
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
                    this._destroyExtraLayoutElements(key);
                    this._layouts[key] = new_layout;
                },

                /*
                 *  Dashboard - currently a single unit.  It isn't
                 *  hard to imagine that the dashboard will become
                 *  more complex, so it's nice for it to have it's own
                 *  layout possibilities.
                 */
                _buildDashLayout: function (layout, unit, key) {
                    // Y.log('window::_buildDashLayout');
                    var YAHOO = Y.YUI2;
                    var center = layout.getUnitByPosition(unit).get("wrap");

                    this._clearContainer(['dt', 'dv']);
                    this._saveMyContainers();

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
                    this._destroyExtraLayoutElements(key);
                    this._layouts[key] = new_layout;
                },

                _onOuterLayoutRender: function (center_layout) {
                    // Y.log('window::_onOuterLayoutRender');
                    this._layouts['outer'].removeListener('render');

                    var buildCenterLayout, onCenterLayoutRender;

                    if (center_layout === 'dash') {
                        buildCenterLayout = this._buildDashLayout;
                        onCenterLayoutRender = 
                            Y.bind(this._onDashLayoutRender, this);
                    }
                    else {
                        buildCenterLayout = this._buildDTDVLayout;
                        onCenterLayoutRender = 
                            Y.bind(this._onDTDVLayoutRender, this);
                    }

                    Y.bind(
                        this._buildLeftLayout,
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
                        Y.bind(this._onLeftLayoutRender, this)
                    );
                    this._layouts['center'].on(
                        'render', 
                        onCenterLayoutRender
                    );

                    this._layouts['left'].render();
                    this._layouts['center'].render();
                },

                _onLeftLayoutRender: function () {
                    // Y.log('window::_onLeftLayoutRender');
                    this._layouts['left'].removeListener('render');
                    Y.bind(
                        this._initMainMenu, 
                        this,                   // context
                        this._layouts['left'],  // layout 
                        'top',                  // unit
                        'vertical'              // menu orientation
                    )();
                },

                _restoreContainerFromCache: function (id, layout, unit_label) {
                    // Y.log('window::_restoreContainerFromCache');
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

                _prepareContainers: function (o) {
                    // Y.log('window::_prepareContainers');
                    if (o.container) {
                        o.container.set('layout', o.layout);
                        o.container.set('layout_unit', o.unit);
                        // make sure the container 
                    }
                    else {
                        // must be a bookmark initialization, 
                        //  so create the containers from history
                        o.creationFn();
                    }
                },

                // Not the best name.
                // First it clears the container's history, then
                //  if the container's widgets are not hidden, this hides them,
                //  which has the side effect of clearing their history. 
                _clearContainer: function (ary) {
                    // Y.log('window::_clearContainer');
                    Y.each(ary, function (v) {
                        var c = this._containers[v];
                        if (c && c.clear) {
                            c.clear();
                        }
                        if (c && c.hideCurrentWidget) {
                            c.hideCurrentWidget();
                        }
                    }, this);
                },

                _onDTDVLayoutRender: function () {
                    // Y.log('window::_onDTDVLayoutRender');
                    var layout = this._layouts['center'];
                    layout.removeListener('render');

                    // attach some event handlers
                    var top = layout.getUnitByPosition('top')
                    top.subscribe('endResize', this._fitDatatableToUnit, 
                                  null, this);
                    top.subscribe('endResize', this._fitDetailViewToUnit, 
                                  null, this);
                    top.subscribe('collapse', this._setCollapsedHeader, {
                        layout: layout, 
                        unit: 'top', 
                        expand_what: 'record set'
                    }, this);
                    

                    // restore our containers
                    if (this._div_cache['manage_datatable']) {
                        this._restoreContainerFromCache(
                            'manage_datatable', layout, 'top'
                        );
                    }
                    if (this._div_cache['manage_detail']) {
                        this._restoreContainerFromCache(
                            'manage_detail', layout, 'center'
                        );
                    }

                    // update container layout info, etc
                    this._prepareContainers({
                        container: this._containers['dt'], 
                        unit: layout.getUnitByPosition('top'),
                        layout: layout,
                        creationFn: Y.bind(this._createDataTableContainer, this)
                    });
                    this._prepareContainers({
                        container: this._containers['dv'], 
                        unit: layout.getUnitByPosition('center'),
                        layout: layout,
                        creationFn: Y.bind(this._createDetailViewContainer, this)
                    });

                    // widgets are loaded from the state of the containers
                    this._executeSubmenuCallback();
                    // Y.log('window:_onDTDVLayoutRender - calling notifyHistory');
                    this._notifyHistory();
                },

                _onDashLayoutRender: function () {
                    // Y.log('window::_onDashLayoutRender');
                    var layout = this._layouts['center'];
                    layout.removeListener('render');

                    if (! this._containers['dash']) {
                        Y.bind(
                            this._initDashboard, 
                            this,                     // context
                            this._layouts['center'],  // layout 
                            'center'                  // unit   
                        )();
                    }
                    else {
                        // restore the container
                        if (this._div_cache['manage_dashboard']) {
                            this._restoreContainerFromCache(
                                'manage_dashboard', layout, 'center'
                            );
                        }
                        this._containers['dash'].show();
                    }
                    this._executeSubmenuCallback();
                    // Y.log('window:_onDashLayoutRender - calling notifyHistory');
                    this._notifyHistory();
                },

                _initMainMenu: function (layout, unit, orientation) {
                    // Y.log('window::_initMainMenu');
                    var menu_unit = layout.getUnitByPosition(unit).body.childNodes[0];
                    this._containers['menu'] = new Y.IC.ManageMenu(
                        {
                            orientation: orientation,
                            render_to: menu_unit
                        }
                    );

                    // need to let the nodemenu's dropdowns spill into the the next unit
                    var cbody = Y.one(layout.getUnitByPosition(unit).body);
                    cbody.addClass('allow-overflow');
                    Y.one(cbody._node.parentNode.parentNode.parentNode).addClass('allow-overflow');

                    // capture the menu events -
                    // 'click' is prevented by the node-menunav plugin, wtf!?
                    // so we use mouse down, but then have to do some clean up..
                    Y.delegate(
                        "mousedown",
                        this._onSubmenuMousedown,
                        this._containers['menu'].get("boundingBox"),
                        'em.yui3-menuitem-content, a.yui3-menuitem-content',
                        this
                    );
                },

                /* 
                 *  Build the dashboard.  this is primative.
                 *  eventually we'll likely want a more complex layout
                 *  for the dashboard, and may load several widgets
                 *  into it.
                 */ 
                _initDashboard: function (layout, unit) {
                    // Y.log('window::_initDashboard');
                    var center = layout.getUnitByPosition(unit);
                    var dash_div = this._initContainerDiv('manage_dashboard', unit);
                    this._containers['dash'] = new Y.IC.ManageDashboard(
                        {
                            prefix: '_da'
                        }
                    );
                    this._containers['dash'].render(dash_div);
                },

                _createDataTableContainer: function () {
                    // Y.log('window::_createDataTableContainer');
                    var top = this._layouts['center'].getUnitByPosition("top");
                    var dt_div = this._initContainerDiv('manage_datatable', top);
                    this._containers['dt'] = new Y.IC.ManageContainer(
                        {
                            render_to: dt_div,
                            prefix: '_dt',
                            layout: this._layouts['center'],
                            layout_unit: top
                        }
                    );

                    // capture clicks on the "detail" link of the option column
                    Y.delegate(
                        "click",
                        this._onDetailClick,
                        this._containers['dt'].get('contentBox'),
                        'a.manage_function_link',
                        this
                    );
                    this._containers['dt'].on(
                        "manageContainer:widgetshown", 
                        Y.bind(this.updateHeaderText, this)
                    );
                    this._containers['dt'].on(
                        "manageContainer:widgetmetadata", 
                        Y.bind(this.updateHeaderText, this)
                    );
                    this._containers['dt'].on(
                        "manageContainer:widgethidden", 
                        Y.bind(this.clearHeaderText, this)
                    );
                },

                _listenToTheList: function (e) {
                    // Y.log('window::_listenToTheList');
                    var widget = this._containers['dt'].get('current');
                    if (widget.detach) {
                        widget.detach('manageFunctionList:rowselected');
                        widget.on(
                            'manageFunctionList:rowselected',
                            function () {
                                this._clearContainer(['dv']);
                                widget._notifyHistory();
                            },
                            this
                        );
                    }
                },

                _createDetailViewContainer: function () {
                    // Y.log('window::_createDetailViewContainer');
                    var center = this._layouts['center'].getUnitByPosition("center");
                    var dv_div = this._initContainerDiv('manage_detail', center);
                    // no detail view container
                    this._containers['dv'] = new Y.IC.ManageContainer(
                        {
                            render_to: dv_div,
                            prefix: '_dv',
                            layout: this._layouts['center'],
                            layout_unit: center
                        }
                    );
                    this._containers['dv'].on(
                        "manageContainer:widgetshown", 
                        Y.bind(this.updateHeaderText, this)
                    );
                    this._containers['dv'].on(
                        "manageContainer:widgetmetadata", 
                        Y.bind(this.updateHeaderText, this)
                    );
                    this._containers['dv'].on(
                        "manageContainer:widgethidden", 
                        Y.bind(this.clearHeaderText, this)
                    );

                },

                _executeSubmenuCallback: function () {
                    if (this._center_layout_onrender_callback) {
                        this._center_layout_onrender_callback();
                        this._center_layout_onrender_callback = null;
                    }
                },

                _onSubmenuMousedown: function (e) {
                    // Y.log('window::_onSubmenuMousedown');

                    // hide the submenu after a selection -- there
                    // seems to be a selection bug in here - should
                    // also clear the selection...
                    menu_nav_node = this._containers['menu'].get("boundingBox");
                    var menuNav = menu_nav_node.menuNav;
                    menuNav._hideAllSubmenus(menu_nav_node);

                    // clear the selection
                    Y.later(500, this, function () {
                        var sel = window.getSelection();
                        sel.removeAllRanges();
                    });

                    if (this.get('state.lc') !== 'dtmax') {
                        // Y.log('window::_onSubmenuMousedown - hiding current widgets');
                        // save a callback because the layout needs to be built/rendered first
                        this._center_layout_onrender_callback = 
                            Y.bind(this._doSubmenuRequest, this, e);
                        // Y.log('window::_onSubmenuMousedown - setting state to dtmax');
                        this.set('state.lc', 'dtmax');
                    }
                    else {
                        this._doSubmenuRequest(e);
                    }

                    // i need to determine if i've selected a list or an add or the dash
                    //  currently i assume every item should render a list...
                },

                _doSubmenuRequest: function (e) {
                    // Y.log('window::_doSubmenuRequest');
                    // if there's no datatable container, create one
                    if (!this._containers['dt']) {
                        this._createDataTableContainer();
                    }
                    // load the Widget into the Data Table container
                    Y.bind(
                        this._containers['dt'].loadWidget, 
                        this._containers['dt']
                    )(e);
                },

                /*
                 * Currently, it is assumed that detail links are only
                 * in the datatables.  If/when that changes, this may
                 * also have to change.
                 *
                 * Loads a inner layout with a short datatable and
                 * large detail view.
                 */
                _onDetailClick: function (e) {
                    // Y.log('window::_onDetailClick');
                    if (this.get('state.lc') !== 'dtdv') {
                        // save a callback, because the layout needs to be built/rendered first
                        this._center_layout_onrender_callback = 
                            Y.bind(this._doDetailRequest, this, e);
                        // Y.log('window::_onDetailClick - setting state to dtdv');
                        this.set('state.lc', 'dtdv');
                    }
                    else {
                        this._doDetailRequest(e);
                    }
                },

                _getOrCreateNodeById: function (id) {
                    var div = Y.one('#' + id);
                    if (!div) {
                        var app_container = Y.one('#ic-manage-app-container');
                        app_container.append(
                            Y.Node.create('<div id="' + id + '"></div>')
                        );
                        div = Y.one('#' + id);
                    }
                    return div;
                },

                onCheckFitness: function (e) {
                    var widget = this._containers['dt'].get('current');
                    // Y.log('window::onCheckFitness - fitted: ' + widget._fitted);
                    if (!widget._fitted)
                        this._fitDatatableToUnit();
                },

                _fitDatatableToUnit: function () {
                    // Y.log('window::_fitDatatableToUnit');
                    var unit = this._layouts['center'].getUnitByPosition("top");
                    var widget = this._containers['dt'].get('current');
                    widget.fitToContainer(unit);
                    // Y.log('made it through _fitDatatableToUnit');
                },

                _fitDetailViewToUnit: function () {
                    // Y.log('window::_fitDetailViewsToUnit');
                    var unit = this._layouts['center'].getUnitByPosition("center");
                    var widget = this._containers['dv'].get('current');
                    if (widget._tabs) {
                        var cb = widget.get('contentBox');
                        var panel = cb.one('div.yui3-tabview-panel');
                        var tabs_height = cb.one('ul.yui3-tabview-list')
                            .get('region').height;
                        var unit_body = Y.one(unit.get('wrap')).one('div.yui-layout-bd');
                        var unit_height = unit_body.get('region').height;
                        var magic = 9; // the 5px border-width?
                        panel.setStyles({
                            height: unit_height - (tabs_height + magic),
                            overflowY: 'scroll'
                        });
                    }
                },

                _initContainerDiv: function (id, unit) {
                    var div = Y.one('#' + id);
                    if (!div) {
                        var unit_body = Y.one(unit.body);
                        unit_body.setContent('');
                        unit_body.append('<div id="' + id + '"></div>');
                        div = Y.one('#' + id);
                    }
                    return div;
                },

                _doDetailRequest: function (e) {
                    // Y.log('window::_doDetailRequest');
                    var top = this._layouts['center'].getUnitByPosition("top");

                    // shrink the top unit and show only 3 rows in the datatable, 
                    //  making room for the detail view without closing the datatable
                    top.set('height', 152);

                    if (this._containers['dt']) {
                        var dt = this._containers['dt'].get('current');
                        // top.set('header', dt.getHeaderText());
                        if (dt instanceof Y.IC.ManageFunctionExpandableList) {
                            // shrink the datatable to 3 rows, scroll the rest
                            this._fitDatatableToUnit();
                        }
                    }

                    // if there's no detail view container, create one
                    if (!this._containers['dv']) {
                        this._createDetailViewContainer();
                    }
                    else {
                        // Y.log('detail view container already exists');
                    }

                    // load the Widget into the Detail View container
                    Y.bind(
                        this._containers['dv'].loadWidget, 
                        this._containers['dv']
                    )(e);
                },

                /*
                 * the inner center layout get's rebuilt frequently,
                 * causing some dom destruction so in order not to
                 * lose our containers (and their cache), we save a
                 * reference to their dom nodes.
                 */
                _saveMyContainers: function () {
                    // Y.log('window::_saveMyContainers');
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

                    if (this._containers['dt']) {
                        createOrSaveContainer(
                            'manage_datatable', 
                            this._div_cache
                        );
                    }
                    if (this._containers['dv']) {
                        createOrSaveContainer(
                            'manage_detail', 
                            this._div_cache
                        );
                    }
                    if (this._containers['dash']) {
                        createOrSaveContainer(
                            'manage_dashboard', 
                            this._div_cache
                        );
                    }
                },

                
                /*
                 * the Layout Manager was having some trouble with
                 * dynamic inner layouts, leaving extra dom nodes all
                 * over the place.  so this is a cleanup method to
                 * destroy any dom left over from a previous inner
                 * layout.
                 */
                _destroyExtraLayoutElements: function (key) {
                    // Y.log('window::_destroyExtraLayoutElements');
                    // destroy any lingering elements from an existing layout
                    if (this._layouts[key]) {
                        Y.each(this._layouts[key]._units, function (v, k, obj) {
                            var id = obj[k].get('id');
                            var node = Y.one('#' + id);
                            if (node) {
                                node.remove();
                                node.destroy(true);
                            }
                            // also detach any event handlers...
                        });
                    }
                },

                /*
                 * Keeps track of our current layout state and
                 * initiates redraws when there's a change.  this
                 * allows us to draw a layout according to the browser
                 * history.
                 */
                _afterStateChange: function (e) {
                    // Y.log('window::_afterStateChange - lc:' + this.get('state.lc'));
                    var state = this.get('state');
                    if (state.lc === undefined) {
                        this._initOuterLayout('dash');
                    }
                    else {
                        if ( ! this._layouts['outer'] ) {
                            this._buildOuterLayout('outer');
                            this._layouts['outer'].on(
                                'render', 
                                Y.bind(this._onOuterLayoutRender, this, state.lc)
                            );
                            this._layouts['outer'].render();
                        }
                        else {
                            var buildCenterLayout, onCenterLayoutRender;
                            if (state.lc === 'dash') {
                                buildCenterLayout = this._buildDashLayout;
                                onCenterLayoutRender = this._onDashLayoutRender;
                            }
                            else {
                                buildCenterLayout = this._buildDTDVLayout;
                                onCenterLayoutRender = this._onDTDVLayoutRender;
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
            "yui2-resize"
        ]
    }
);
