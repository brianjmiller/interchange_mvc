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

/* See global YUI_config object in views/manage/index.tst */

YUI().use(
    "ic-manage-window",
    function (Y) {
        Y.Node.prototype.setNumberSignClass = function (value) {
            var POSITIVE = 'positive',
                NEGATIVE = 'negative';

            if (value < 0) {
                this.replaceClass(POSITIVE, NEGATIVE);
            }
            else if (value > 0) {
                this.replaceClass(NEGATIVE, POSITIVE);
            }
            else {
                this.removeClass(POSITIVE);
                this.removeClass(NEGATIVE);
            }

            return this;
        };

        Y.on(
            "domready",
            function () {
                // Y.log("firing dom ready event");

                // Y.log("setting up manage window");
                var mw = Y.IC.ManageWindow();

                // remove our loading screen
                Y.on(
                    "contentready",
                    function () {
                        Y.one("#application-loading").remove();
                    },
                    "#manage_window_content_pane"
                );
            }
        );
    }
);
