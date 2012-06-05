YUI.add(
    "ic-manage-ml-filterable-by_status",
    function (Y) {
        var Clazz = Y.namespace("IC.Manage.ML.Filterable").ByStatus = Y.Base.create(
            "ic_manage_ml_filterable_by_status",
            Y.Plugin.Base,
            [],
            {
                initializer: function (config) {
                    Y.log("initializer", "debug", Clazz.NAME);
                    var host = this.get("host"),
                        status = this.get("statusCode")
                    ;

                    this.onHostEvent(
                        "add",
                        function (e) {
                            Y.log("initializer - onHost add: " + e.model, "debug", Clazz.NAME);
                            if (e.model.get("status_code") !== status) {
                                e.preventDefault();
                            }
                        },
                        this
                    );

                    this.afterHostEvent(
                        host.model.NAME + ":status_codeChange",
                        function (e) {
                            Y.log("initializer - afterHost status_code change: " + e.newVal, "debug", Clazz.NAME);
                            if (e.newVal !== status) {
                                host.remove(e.target);
                            }
                        },
                        this
                    );

                    this.afterHostMethod(
                        "_syncURLParams",
                        function (action) {
                            Y.log("initializer - afterHost _syncURLParams: " + action, "debug", Clazz.NAME);
                            if (! Y.Do.originalRetVal["query"]) {
                                Y.Do.originalRetVal.query = [];
                            }
                            Y.Do.originalRetVal.query.push("status_code", status);
                        }
                    );
                }
            },
            {
                NS: "mlFilterByStatus",

                ATTRS: {
                    statusCode: {
                        value:     null,
                        validator: Y.Lang.isString
                    }
                }
            }
        );
    },
    "0.0.1",
    {
        requires: [
            "plugin"
        ]
    }
);
