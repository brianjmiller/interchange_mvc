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
    "ic-util",
    function(Y) {
        Y.namespace("IC.Util");

        Y.IC.Util.areEqualObjects = function (a, b) {
            //Y.log('Y.IC.Util::areEqualObjects');
            var equal = true;

            if (typeof(a) != typeof(b)) {
                return false;
            }

            var allkeys = {};
            for (var j in a) {
                allkeys[j] = 1;
            }
            for (var k in b) {
                allkeys[k] = 1;
            }

            Y.some(
                allkeys,
                function (v, i, obj) {
                    if (a.hasOwnProperty(i) != b.hasOwnProperty(i)) {
                        if (
                            (a.hasOwnProperty(i) && Y.Lang.isFunction(b[i]))
                            ||
                            (a.hasOwnProperty(i) && Y.Lang.isFunction(b[i]))
                        ) {
                            return;
                        }
                        else {
                            //Y.log('Y.IC.Util::areEqualObjects - failed on missing property');
                            equal = false;
                            return true;
                        }
                    }
                    if (typeof(a[i]) !== typeof(b[i])) {
                        //Y.log('Y.IC.Util::areEqualObjects - failed on matching types');
                        equal = false
                        return true;
                    }
                    if (Y.Lang.isObject(a[i])) {
                        if (! Y.IC.Util.areEqualObjects(a[i], b[i])) {
                            equal = false;
                            return true;
                        }
                    }
                    else {
                        if (a[i] !== b[i]) {
                            //Y.log('Y.IC.Util::areEqualObjects - failed on matching values');
                            equal = false;
                            return true;
                        }
                    }
                }
            );            

            return equal;
        };
    },
    "@VERSION@",
    {}
);
