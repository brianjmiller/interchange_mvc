YUI.add(
    "ic-manage-widget-dashboard",
    function(Y) {
        var ManageDashboard;

        var Lang = Y.Lang,
            Node = Y.Node
        ;

        ManageDashboard = function (config) {
            ManageDashboard.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageDashboard,
            {
                NAME: "ic_manage_dashboard",
                ATTRS: {
                    update_interval: {
                        value: "60",
                        validator: Lang.isNumber
                    },
                    last_updated: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageDashboard,
            Y.Widget,
            {
                initializer: function(config) {
                    Y.log("dashboard initializer");
                },

                renderUI: function() {
                    var contentBox = this.get("contentBox");

                    contentBox.setContent("");
                    contentBox.appendChild(
                        Node.create("<div>The Dashboard w00t w00t</div>")
                    );
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageDashboard = ManageDashboard;
    },
    "@VERSION@",
    {
        requires: [
            "widget",
        ]
    }
);
