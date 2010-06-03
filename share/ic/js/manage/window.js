YUI.add(
    "ic-manage-window",
    function (Y) {
        var ManageWindow;

        // Constructor //
        ManageWindow = function (config) {
            ManageWindow.superclass.constructor.apply(this, arguments);
        };

        // Static //
        Y.mix(
            ManageWindow,
            {
                NAME: "ic_manage_window",
                ATTRS: {
                }
            }
        );

        // Prototype //
        Y.extend(
            ManageWindow,
            Y.Base,
            {
                // Instance Members //
                _menu:         null,
                _container:    null,
                _subcontainer: null,

                // Base Methods //
                initializer: function (config) {
                    Y.one("#manage_window").setContent("");

                    var YAHOO = Y.YUI2;

                    var menu_unit;
                    var container_unit;

                    var layout = new YAHOO.widget.Layout(
                        {
                            units: [
                                {
                                    position: "top",
                                    height: 50,
                                    body: "manage_header"
                                },
                                {
                                    position: "left",
                                    body: "manage_subcontainer",
                                    width: 250,
                                    resize: true,
                                    animate: true
                                },
                                {
                                    position: "center",
                                    body: "manage_window"
                                },
                                {
                                    position: "bottom",
                                    body: "manage_footer",
                                    height: 40
                                }
                            ]
                        }
                    );
                    layout.on(
                        "render",
                        function () {
                            var center = layout.getUnitByPosition("center").get("wrap");

                            var inner_layout = new YAHOO.widget.Layout(
                                center,
                                {
                                    parent: layout,
                                    minWidth: 400,
                                    minHeight: 200,
                                    units: [
                                        {
                                            position: "center",
                                            scroll: true,
                                        }
                                    ]
                                }
                            );
                            inner_layout.render();

                            container_unit = inner_layout.getUnitByPosition("center").get("wrap");
                        }
                    );
                    layout.render();

                    this._menu      = new Y.IC.ManageMenu(
                        {
                            render_to: container_unit
                        }
                    );
                    this._container = new Y.IC.ManageContainer(
                        {
                            render_to: container_unit
                        }
                    );

                    Y.delegate(
                        "mousedown",
                        Y.bind(this._container._handleLoadWidget, this._container),
                        this._menu.get("boundingBox"),
                        'em.yui3-menuitem-content'
                        //this._menu
                    );
                    Y.delegate(
                        "mousedown",
                        Y.bind(this._container._handleLoadWidget, this._container),
                        this._menu.get("boundingBox"),
                        'a.yui3-menuitem-content'
                        //this._menu
                    );
                },

                destructor: function () {
                    this._menu         = null;
                    this._container    = null;
                    this._subcontainer = null;
                }

                // Public Methods //

                // Private Methods //
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
            "yui2-layout",
            "yui2-animation"
        ]
    }
);
