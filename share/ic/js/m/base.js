YUI.add(
    "ic-m-base",
    function (Y) {
        //
        // this is a *very* poor man's trait type thing, basically add our own
        // properties to the config object for an attribute
        //
        Y.Base._ATTR_CFG.concat("toJSON");
        Y.Base._ATTR_CFG_HASH.toJSON = true;

        var Clazz = Y.namespace("IC.M").Base = Y.Base.create(
            "ic_m_base",
            Y.Model,
            [ Y.IC.ModelConsumer ],
            {   
                toJSON: function () {
                    var attrs = Clazz.superclass.toJSON.apply(this, arguments);
                    Y.each(
                        attrs,
                        function (v, k, o) {
                            var attr_cfg = this._getAttrCfg(k);
            
                            if (Y.Lang.isValue(attr_cfg.toJSON) && ! attr_cfg.toJSON) {
                                delete attrs[k];
                            }
                        },
                        this
                    );
            
                    return attrs;
                }
            },
            {}
        );
    },
    "0.0.1",
    {
        requires: [
            "model",
            "ic-model-consumer"
        ]
    }
);
