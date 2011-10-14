YUI.add(
    "ic-model-consumer",
    function (Y) {
        //
        // this is a *very* poor man's trait type thing, basically add our own
        // properties to the config object for an attribute
        //
        Y.Base._ATTR_CFG.concat("mlClass");
        Y.Base._ATTR_CFG_HASH.mlClass = true;
        Y.Base._ATTR_CFG.concat("mClass");
        Y.Base._ATTR_CFG_HASH.mClass = true;

        function ModelConsumer (config) {}

        ModelConsumer.prototype = {
            _setML: function (list, name) {
                var existing_list = this.get(name);
                if (existing_list) {
                    return existing_list.reset(list);
                }

                var ml_class = this._getAttrCfg(name).mlClass;

                var new_list = new ml_class (
                    {
                        bubbleTargets: this
                    }
                );
                new_list.reset(list);
    
                return new_list;
            },

            _setM: function (cfg, name) {
                var m_class = this._getAttrCfg(name).mClass;
    
                if (cfg instanceof m_class) {
                    return cfg; 
                }
            
                var load = false;
                if (! Y.Lang.isObject(cfg)) {
                    cfg = {
                        id: cfg
                    };
                    load = true;
                }

                var m = new m_class (cfg);
                if (load) {
                    m.load();
                }

                return m;
            }
        };

        Y.namespace("IC").ModelConsumer = ModelConsumer;
    },
    "0.0.1",
    {   
        requires: []
    }
);

