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
                if (cfg && ! Y.Lang.isObject(cfg)) {
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

