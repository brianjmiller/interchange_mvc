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
            [],
            {
                toJSON: function () {
                    Y.log(Clazz.NAME + "::toJSON");
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
            "model"
        ]
    }
);
