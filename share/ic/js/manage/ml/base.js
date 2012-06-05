YUI.add(
    "ic-manage-ml-base",
    function (Y) {
        var Clazz = Y.namespace("IC.Manage.ML").Base = Y.Base.create(
            "ic_manage_ml_base",
            Y.ModelList,
            [],
            {
                _serverManageClass: null,

                _syncURLParams: function (action) {
                    return {};
                },

                sync: function (action, options, callback) {
                    Y.log("sync", "debug", Clazz.NAME);
                    Y.log("sync - action: " + action, "debug", Clazz.NAME);
                    var url, url_params = this._syncURLParams(action);

                    switch (action) {
                        case 'read':
                            this.set("message", "Fetching...");

                            url = "/manage/" + this._serverManageClass + "/data?_format=json&config=" + encodeURIComponent( Y.JSON.stringify(url_params) );

                            Y.io(
                                url,
                                {
                                    on: {
                                        success: function (txnId, response) {
                                            var new_list = [],
                                                model_refs
                                            ;

                                            this.set("message", "Data retrieved...");

                                            model_refs = this.parse(response.responseText);
                                            Y.log("sync - success - model_refs.length: " + model_refs.length, "debug", Clazz.NAME);

                                            if (model_refs.length > 0) {
                                                Y.each(
                                                    model_refs,
                                                    function (model_ref, i, a) {
                                                        Y.log("sync - success - model_ref: " + Y.dump(model_ref), "debug", Clazz.NAME);
                                                        var model = this.getById(model_ref.id);
                                                        if (! model) {
                                                            model = new this.model (model_ref);
                                                        }
                                                        else {
                                                            model.setAttrs(model_ref);
                                                        }

                                                        new_list.push(model);
                                                    },
                                                    this
                                                );
                                            }
                                            this.reset(new_list);

                                            this.set("message", "Last loaded: " + new Date ());

                                            if (Y.Lang.isFunction(callback)) {
                                                callback(null, response.responseText);
                                            }
                                        },
                                        failure: function (txnId, response) {
                                            this.set("message", "Last try: " + new Date ());

                                            if (Y.Lang.isFunction(callback)) {
                                                callback("Failed to load data: " + response);
                                            }
                                        }
                                    },
                                    context: this
                                }
                            );

                        default:
                            if (Y.Lang.isFunction(callback)) {
                                callback("Invalid action: " + action);
                            }
                    }
                },

                //
                // TODO: do we even need to do this or are we better off making the server side
                //       just return a JSON array of data?
                //
                parse: function (response) {
                    Y.log("parse", "debug", Clazz.NAME);
                    this.set("message", "Parsing...");
                    if (Y.Lang.isString(response)) {
                        try {
                            var object = Clazz.superclass.parse.apply(this, arguments);

                            this.set("message", "Number found: " + (object.results ? object.results.length : "--"));
                            return object.results || [];
                        }
                        catch (ex) {
                            this.fire(
                                "error",
                                {
                                    error:    ex,
                                    response: response,
                                    src:      "parse"
                                }
                            );

                            return null;
                        }
                    }

                    return response || [];
                }
            },
            {
                ATTRS: {
                    message: {
                        value:     '',
                        validator: Y.Lang.isString
                    }
                }
            }
        );
    },
    "0.0.1",
    {
        requires: [
            "model-list"
        ]
    }
);
