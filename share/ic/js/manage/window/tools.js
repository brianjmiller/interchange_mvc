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
    "ic-manage-window-tools",
    function(Y) {
        var ManageTools;

        ManageTools = function (config) {
            ManageTools.superclass.constructor.apply(this, arguments);
        };

        Y.mix(
            ManageTools,
            {
                NAME: "ic_manage_tools",
                ATTRS: {
                    // the window I'm in
                    window: {
                        value: null
                    },
                    // the layout manager i'm a child of
                    layout: {
                        value: null
                    },
                    // the layout_unit i'm inside
                    layout_unit: {
                        value: null
                    }
                }
            }
        );

        Y.extend(
            ManageTools,
            Y.Widget,
            {
                ACTIONS: 0,
                FORMS: 1,
                LINKS: 2,
                _accordion: null,

                initializer: function (config) {
                    //Y.log("manage_tools::initializer");
                    this.render(config.render_to);
                },

                destructor: function () {
                    this._accordion.destroy();
                    this._accordion = null;
                },

                renderUI: function () {
                    //Y.log('manage_tools::renderUI');

                    var content_height = this._getContentHeight();
                    var empty_node = Y.Node.create('<span />');

                    this._accordion = new Y.Accordion(
                        {
                            srcNode: this.get('contentBox'),
                            useAnimation: true,
                            collapseOthersOnExpand: true
                        }
                    );
                    this._accordion.render();

                    // TODO: can we make the content of each accordion item just be
                    //       a widget itself so that this module can be dumb about
                    //       what is actually inside of them?

                    var actions = new Y.AccordionItem(
                        {
                            label: 'Common Actions',
                            expanded: true,
                            id: 'ql-actions',
                            contentHeight: {
                                method: 'fixed',
                                height: content_height
                            },
                            icon: empty_node,
                            iconAlwaysVisible: empty_node
                        }
                    );
                    actions.set('bodyContent', this._getActionsContent());

                    var forms = new Y.AccordionItem(
                        {
                            label: 'Quick Access',
                            expanded: false,
                            id: 'ql-forms',
                            contentHeight: {
                                method: 'fixed',
                                height: content_height
                            },
                            icon: empty_node,
                            iconAlwaysVisible: empty_node
                        }
                    );
                    forms.set('bodyContent', 'Loading...');

                    var links = new Y.AccordionItem(
                        {
                            label: 'Your Links',
                            expanded: false,
                            id: 'ql-links',
                            contentHeight: {
                                method: 'fixed',
                                height: content_height
                            },
                            icon: empty_node,
                            iconAlwaysVisible: empty_node
                        }
                    );
                    links.set('bodyContent', 'Loading...');

                    this._accordion.addItem(actions);
                    this._accordion.addItem(forms);
                    this._accordion.addItem(links);

                    this._getFormsContent( forms.getStdModNode(Y.WidgetStdMod.BODY) );

                    Y.StorageLite.on(
                        'storage-lite:ready',
                        Y.bind(
                            this._getLinksContent,
                            this,
                            links.getStdModNode( Y.WidgetStdMod.BODY )
                        )
                    );
                },

                bindUI: function () {
                    //Y.log('manage_tools::bindUI');
                    this.get('layout').subscribe(
                        'resize', 
                        Y.bind(this._resizeAccItems, this)
                    );
                },

                syncUI: function () {
                    //Y.log('manage_tools::syncUI');
                },

                _resizeAccItems: function (e) {
                    //Y.log('manage_tools::_resizeAccItems');
                    var new_height = this._getContentHeight();

                    Y.each(
                        this._accordion.get('items'),
                        function (v) {
                            v.set(
                                'contentHeight',
                                {
                                    method: 'fixed', 
                                    height: new_height
                                }
                            );
                            if (v.get('expanded')) {
                                var body = v.getStdModNode(Y.WidgetStdMod.BODY);
                                body.setStyle('height', new_height);
                            }
                            else {
                                this._accordion._collapseItem(v);
                            }
                        },
                        this
                    );
                },

                _getContentHeight: function () {
                    //Y.log('manage_tools::_getContentHeight');
                    var unit          = this.get('layout_unit');
                    var unit_height   = unit.getSizes().body.h;
                    var num_items     = 3;
                    var header_height = 24;
                    var height        = unit_height - (header_height * 3);

                    if (height < 40) height = 40;

                    return height;
                },

                // TODO: need to build the common actions based on config from server
                //       makes it similar to how the manage menu works
                _getActionsContent: function () {
                    return '\
<div style="position: relative;">\
    <h4>Common Actions</h4>\
    <ul>\
        <li>\
            <a>Action 1</a>\
        </li>\
        <li>\
            <a>Action 2</a>\
        </li>\
    </ul>\
</div>'
                },

                _loadProfile: function (profile, state) {
                    var new_state = Y.merge(profile, state);

                    //Y.IC.ManageHistory.setHistory(null, new_state);
                },

                // TODO: need to build the quick access content based on config from server
                _getFormsContent: function (node) {
                    node.setContent('');

                    // add the goto order form
                    var fields = [];
                    fields[0] = {
                        name: '_pk_id',
                        label: 'Find Order By ID #',
                        required: true,
                        validator: function (val, field) {
                            if (val.toString().length > 15) return false;
                            return true;
                        }
                    }
                    fields[1] = {
                        type: 'button',
                        label: 'Submit'
                    };

                    var form1 = new Y.IC.Form(
                        {
                            method: 'get',
                            children: fields
                        }
                    );
                    form1.render(node);

                    //var form1_node = form1._formNode;
                    //form1_node.plug(Y.Form.Values);
                    //form1_node.one('button').on(
                        //'click',
                        //function (e) {
                            //e.stopPropagation();

                            //var values = form1_node.values.getValues();

                            // TODO: restore handling

                            // TODO: I'm not sure we really want to clear the form
                            //form1.reset();
                        //},
                        //this
                    //);

                    // add the goto product 
                    fields = [];
                    fields[0] = {
                        name: 'sku',
                        label: 'Search For Product By SKU',
                        required: true,
                        validator: function (val, field) {
                            if (val.toString().length > 30) return false;
                            return true;
                        }
                    }
                    fields[1] = {type: 'button', label: 'Search'};

                    var form2 = new Y.IC.Form(
                        {
                            method: 'get',
                            children: fields
                        }
                    );
                    form2.render(node);

                    //var form2_node = form2._formNode;
                    //form2_node.plug(Y.Form.Values);
                    //form2_node.one('button').on(
                        //'click',
                        //function (e) {
                            //e.stopPropagation();

                            //// TODO: finish refactoring this
                            //this.get("window").fire(
                                //"manage_window:contentPaneShowContent",
                                //'function',
                                //'Products',
                                //'List',
                                //''
                            //);
                            //return;

                            //var values  = form2_node.values.getValues();
                            //var args    = 'Products_productList-search_by[]=sku%3Dilike&sku=' + values.sku

                            // TODO: restore handling

                            // TODO: I'm not sure we really want to clear the form
                            //form2.reset();
                        //},
                        //this
                    //);
                },

                _createPageLink: function (e) {
                    // Y.log('_createPageLink');
                    var links = [];
                    if (Y.StorageLite.length()) {
                        links = Y.StorageLite.getItem('ic_links', true);
                    }

                    var name = prompt('Provide a name for this link:', '[link name]');
                    if (name !== null) {
                        links.unshift(
                            {
                                name: name,
                                //state: Y.HistoryLite.get()
                            }
                        );
                        Y.StorageLite.setItem('ic_links', links, true);
                        this._getLinksContent(
                            this._accordion.getItem(this.LINKS).getStdModNode(Y.WidgetStdMod.BODY)
                        );
                    }
                },

                _removePageLink: function (index) {
                    var links = [];
                    if (Y.StorageLite.length()) {
                        links = Y.StorageLite.getItem('ic_links', true);
                    }
                    try {
                        links.splice(index, 1);
                        Y.StorageLite.setItem('ic_links', links, true);
                        this._getLinksContent(
                            this._accordion.getItem(this.LINKS)
                                .getStdModNode(Y.WidgetStdMod.BODY)
                        );
                    } catch (err) {
                        Y.log("Can't remove page link: " + err);
                    }
                },

                _getLinksContent: function (node) {
                    node.setContent('');

                    // first, make a button that get's the current history 
                    //  and stores it as a recallable link.
                    var link_button = Y.Node.create(
                        '<button>Link This Page</button>'
                    );
                    link_button.on(
                        'click', 
                        Y.bind(this._createPageLink, this)
                    );
                    node.append(link_button);

                    // then build the list of links, 
                    //  (having the format [ {name: 'link name', state: {...} } ]
                    //  each with a delete button that remove the link
                    node.append(Y.Node.create('<h4>Saved Links</h4>'));

                    var links      = Y.Node.create('<ul></ul>');
                    var link_items = Y.StorageLite.getItem('ic_links', true);

                    if (link_items && link_items.length) {
                        Y.each(
                            link_items,
                            function (link, i) {
                                var link_node = Y.Node.create(
                                    '<a href="" class="ql-link">' + link.name + '</a>'
                                );
                                link_node.on(
                                    'click',
                                    Y.bind(
                                        function (e) {
                                            e.halt();
                                            this._loadProfile({}, link.state);
                                        },
                                        this
                                    )
                                );

                                var del_node = Y.Node.create(
                                    '<a href="" class="ql-remove">[remove]</a>'
                                );
                                del_node.on(
                                    'click',
                                    Y.bind(
                                        function (e) {
                                            e.halt();
                                            this._removePageLink(i);
                                        },
                                        this
                                    )
                                );

                                var list_item = Y.Node.create('<li class="clearfix"></li>');
                                list_item.append(link_node);
                                list_item.append(del_node);
                                links.append(list_item);
                            },
                            this
                        );
                    }
                    else {
                        // add a little instruction/description
                        links.append('\
<li class="clearfix instructions">\
  Use the above "Link This Page" button to save links to frequently used\
  searches or detail pages.\
</li>'
                        );
                    }
                    node.append(links);
                }
            }
        );

        Y.namespace("IC");
        Y.IC.ManageTools = ManageTools;
    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-window-tools-css", 
            "anim",
            "widget",
            "gallery-accordion-css",
            "gallery-accordion",

            // Used by the "Your Links" accordion item
            "gallery-storage-lite",

            // Used by "Quick Access" accordion item
            "gallery-form-values",
            "ic-form"
        ]
    }
);
