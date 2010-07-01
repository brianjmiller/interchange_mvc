       /**
        * Simple Treeview
        *
        * Copyright (c) 2010 Matt Parker, Lamplight Database Systems Ltd
        * YUI BSD - http://developer.yahoo.com/yui/license.html
        */
       /**
        * Really lightweight treeview plugin that can be attached to a Node via the plug method.
        * It's just a listener and some css
        * @class TreeviewLite
        * @constructor
        * @namespace Plugin
        */



YUI.add(
    "ic-manage-plugin-treeview",
    function(Y) {

        // for minimizing
        var HOST            = "host",
            TREEVIEWLITE    = "treeviewlite",
            getCN           = Y.ClassNameManager.getClassName,
            CSS_TOP         = getCN( TREEVIEWLITE ), //"yui3-treeviewlite",
            CSS_HAS_CHILD   = getCN( TREEVIEWLITE , "haschild" ), //"yui3-treeviewlite-haschild", 
            CSS_FINAL_CHILD = getCN( TREEVIEWLITE , "lastchild" ), //"yui3-treeviewlite-lastchild",
            CSS_COLLAPSED   = getCN( TREEVIEWLITE , "collapsed" ), //"yui3-treeviewlite-collapsed";
            CSS_CLEARED     = getCN( TREEVIEWLITE , "cleared" ), //"yui3-treeviewlite-cleared";

        TreeviewLite = function(config) {
            TreeviewLite.superclass.constructor.apply(this, arguments);
        };
        
        /**
        * @property NAME
        * @type {String}
        */
        TreeviewLite.NAME = "treeviewLitePlugin";

        /**
        * @property NS
        * @description The treeview instance will be placed on the Node instance 
        *         under the treeviewlight namespace. It can be accessed via Node.treeviewlight;
        * @type {String}
        */
        TreeviewLite.NS = "treeviewLite";

        TreeviewLite.LABEL_NODE_TEMPLATE = '\
<span class="treeview-label treeview-toggle"></span>';
        TreeviewLite.MENU_TEMPLATE = '\
<div class="yui3-menu yui3-menu-horizontal yui3-menubuttonnav treeview-menu">\
  <div class="yui3-menu-content">\
    <ul>\
    </ul>\
  </div>\
</div>';
        TreeviewLite.MENU_CONTAINER_TEMPLATE = '\
<div class="yui3-menu treeview-menu"></div>';
        TreeviewLite.MENU_CONTENT_TEMPLATE = '\
<div class="yui3-menu-content"></div>';
        TreeviewLite.MENU_ITEM_TEMPLATE = '\
<li class="yui3-menuitem treeview-goto"></li>';
        TreeviewLite.MENU_ITEM_CONTENT_TEMPLATE = '\
<span class="yui3-menuitem-content"></span>'
        TreeviewLite.EXPAND_TEMPLATE = '\
<span class="treeview-action treeview-expand">Expand All</span>';
        TreeviewLite.COLLAPSE_TEMPLATE = '\
<span class="treeview-action treeview-collapse">Collapse All</span>';
        TreeviewLite.SHOW_MENU_TEMPLATE = '\
<span class="treeview-action treeview-menu-toggle">Show Menu</span>';
        TreeviewLite.EXPAND_MENUITEM_TEMPLATE = '\
<li class="yui3-menuitem treeview-expand">\
  <a class="yui3-menuitem-content">Expand All</a>\
</li>';
        TreeviewLite.COLLAPSE_MENUITEM_TEMPLATE = '\
<li class="yui3-menuitem treeview-collapse">\
  <a class="yui3-menuitem-content">Collapse All</a>\
</li>';
        TreeviewLite.SHOW_MENUITEM_TEMPLATE = '\
<li>\
  <a class="yui3-menu-label" href="#foo"><em>Show Menu</em></a>\
  <div class="yui3-menu">\
    <div class="yui3-menu-content">\
      <ul>\
      </ul>\
    </div>\
  </div>\
</li>';

        /**
         * There are no attributes to set.  It's that simple.
         */
        TreeviewLite.ATTRS = {
            menu: {
                value: null
            }
        };
        
        Y.extend(TreeviewLite, Y.Plugin.Base, {
            
            /**
             * Stores handles for delegated event listener(s).
             * @property _delegates
             * @protected
             * @type Array
             */
            _delegates: [],
            
            /**
             * Lifecycle: add classes and a delegated listener
             * @method initializer
             */
            initializer: function () {
              this.renderUI();
              this.bindUI();
            },
            
            /**
             * Lifecycle: removes classes and listener(s)
             * @method destructor
             */
            destructor: function () {
              var host = this.get(HOST);
              
              host.removeClass(CSS_TOP);
              host.all("li").removeClass(CSS_HAS_CHILD)
                            .removeClass(CSS_COLLAPSED)
                            .removeClass(CSS_FINAL_CHILD);
              // remove event(s);
              Y.each(this._delegates , function(d){d.detach( );});
            },

            /**
             * <p>Adds some CSS to the various nodes in the tree.</p>
             * @method bindUI
             */
            renderUI : function () {
              var host = this.get(HOST);
              
              host.addClass(CSS_TOP);
              
              Y.each(host.all("li") , function (n) { 
                   // add class if they have child lists
                   n.removeClass( CSS_HAS_CHILD );
                   if(n.one("ol li,ul li")) {
                       n.addClass(CSS_HAS_CHILD);
                   }
                   
                   // add a 'last child' css.
                   n.removeClass(CSS_FINAL_CHILD);
                   if (n.next() === null) {
                     n.addClass(CSS_FINAL_CHILD);
                   }
              });            
            },

            /**
             * <p>Adds a delegated listener to the top of the tree
             * to open toggle the collapsed state of any list item
             * containing a nested list.</p>
             * @method bindUI
             */
            bindUI : function () {
                // Y.log('treeview::bindUI');
                /*
                 * Because treeview is plugged in multiple times,
                 * I need to be careful not to bind the same event
                 * more than once.
                 */
                this._bindOnce(
                    'treeview-toggle', 'click', this._toggleCollapse
                );
                this._bindOnce(
                    'treeview-expand', 'click', this._expandTree
                );
                this._bindOnce(
                    'treeview-collapse', 'click', this._collapseTree
                );
            },

            _bindOnce: function (selector, action, fn) {
                var items = this.get(HOST).all('span.' + selector);
                this._delegates.push(
                    items.on(action, fn, this)
                );
                items.removeClass(selector);
            },

            _doAction: function (e, action, bool, selector, parent) {
                // Y.log('treeview::_doAction');
                if (!parent) parent = e.target.get("parentNode");
                
                parent.removeClass(CSS_CLEARED);
                if (parent.test('li') && 
                    (parent.hasClass(CSS_COLLAPSED) == bool) ) { 
                    this.fire(action, e);
                    if (bool) parent.removeClass(CSS_COLLAPSED);
                    else parent.addClass(CSS_COLLAPSED);
                }
                var lis = parent.all(selector);
                if (lis.size() > 0) {
                    Y.each(lis, function (li, i) {
                        // ducktype the event
                        this.fire(action, {target: li.one('span')});
                        li.removeClass(CSS_CLEARED);
                        if (bool) li.removeClass(CSS_COLLAPSED);
                        else li.addClass(CSS_COLLAPSED);
                    }, this);
                }
            },

            _collapseTree: function (e, parent) {
                // Y.log('treeview::_collapseTree');
                this._doAction(e, 'collapse', false, 
                               'li.yui3-treeviewlite-haschild', parent);
            },

            _expandTree: function (e, parent) {
                // Y.log('treeview::_expandTree');
                this._doAction(e, 'open', true, 
                               'li.yui3-treeviewlite-collapsed', parent);
            },

            addTopLevelMenu: function (panel) {
                var ul = this.get('host');
                var parent = ul.get('parentNode');
                var lis = ul.get('children');
                //  add menu with 'menu/expand/collapse'
                if (lis.size() > 0) {
                    var menu = Y.Node.create(
                        Y.IC.ManageTreeview.MENU_TEMPLATE
                    );
                    // walk the DOM and build the submenu
                    var lis = panel.all('ul.yui3-treeviewlite>li');
                    var show = Y.Node.create(
                        Y.IC.ManageTreeview.SHOW_MENUITEM_TEMPLATE
                    );
                    var show_ul = show.one('ul');
                    var prev_depth = 0;  // for adjusting the nest padding
                    var adjust = 0;      // for adjusting the nest padding
                    Y.each(lis, function (li) {
                        // get depth info and pad to show nesting
                        var depth = li.getAttribute('depth');
                        var pad = '';
                        for (var i=0; i < (Number(depth) - adjust); i++)
                            pad += '&nbsp;&nbsp;&nbsp;&nbsp;';
                        // do some silly adjustment, due to the way depth is set
                        if (depth < prev_depth)
                            adjust += prev_depth - depth;
                        else prev_depth = depth;
                        // add the menu item
                        var label = li.one('span.treeview-label');
                        if (label) {
                            var item = Y.Node.create(
                                Y.IC.ManageTreeview.MENU_ITEM_TEMPLATE
                            );
                            var link_to = li.getAttribute('id');
                            item.setAttribute('for', link_to);
                            var link = Y.Node.create(
                                Y.IC.ManageTreeview.MENU_ITEM_CONTENT_TEMPLATE
                            );
                            link.setContent(pad + label.get('innerHTML'));
                            item.append(link);
                            // link-up each submenu item to it's teemenu item
                            item.on('click', this._gotoItem, this, link_to);
                            show_ul.append(item);
                        }
                    }, this);
                    var menu_ul = menu.one('ul');
                    menu_ul.append(show);

                    // add the top level Expand All action
                    var expand = Y.Node.create(
                        Y.IC.ManageTreeview.EXPAND_MENUITEM_TEMPLATE
                    );
                    expand.on('click', this._expandTree, this, parent);
                    menu_ul.append(expand);

                    // add the top level Collapse All action
                    var collapse = Y.Node.create(
                        Y.IC.ManageTreeview.COLLAPSE_MENUITEM_TEMPLATE
                    );
                    collapse.on('click', this._collapseTree, this, parent);
                    menu_ul.append(collapse);

                    // make it a real menu, and put it in place
                    menu.plug(Y.Plugin.NodeMenuNav);
                    ul.insert(menu, ul);
                }
            },

            _gotoItem: function (e, id) {
                // Y.log('treeview::_gotoItem id:' + id);
                var item = Y.one('#' + id);

                // build a list of ancestors, and find the root
                var ancestors = item.ancestors('ul.yui3-treeviewlite>li');
                var root = item;
                if (ancestors.size())
                    root = Y.one(ancestors._nodes[ancestors.size()-1]);

                // collapse everything, using the toplevel menu
                var ul = root.get('parentNode');
                var toplevel_menu = ul.previous('div.treeview-menu');
                var treeview = ul.treeviewLite;
                treeview._collapseTree({}, Y.one(toplevel_menu.get('parentNode')));

                // add event listeners to scroll the item into view once ready
                var container = toplevel_menu.ancestor('div.yui3-tabview-panel');
                var mtp = item.one('div.yui3-widget-stdmod').mtp;
                if (mtp.get('uri'))
                    mtp.on('manageTabPanel:srcloaded', function (e) {
                        item.scrollToTop(container);
                    });
                else if (mtp.get('content'))
                    mtp.on('manageTabPanel:contentloaded', function (e) {
                        item.scrollToTop(container);
                    });

                // expand and clear all of it's ancestors/siblings
                Y.each(ancestors, function (ancestor) {
                    this._expandAndClear(ancestor);
                }, this);
                Y.each(item.siblings('li'), function (sibling) {
                    this._expandAndClear(sibling);
                }, this);

                // then open it and scroll it into view
                item.removeClass(CSS_COLLAPSED);
                this.fire('open', {target: item.one('span.treeview-label')});
            },

            _expandAndClear: function (li) {
                // Y.log('treeview::_expandAndClear');
                var mtp = li.one('div.yui3-widget-stdmod').mtp;
                if (mtp.get('headerContent')) mtp.set('headerContent', '');
                if (mtp.get('bodyContent')) mtp.set('bodyContent', '');
                li.addClass(CSS_CLEARED);
            },

            /**
             * <p>Opens or collapses a nested list.</p>
             * @method _toggleCollapse
             * @param {EventFacade} e Event object
             * @protected 
             */
            _toggleCollapse : function (e){
                // Y.log('treeview::_toggleCollapse');
                var parent = e.currentTarget.get("parentNode");
                if( parent.one("ol,ul") ){
                    if( parent.hasClass(CSS_COLLAPSED) ) { 
                        /**
                         * <p>Event fired when a list is opened</p>
                         * @event open
                         * @param {EventFacade} ev Event object
                         */
                        this.fire("open" , e);
                    } else {
                        /**
                         * <p>Event fired when a list is collapsed</p>
                         * @event collapse
                         * @param {EventFacade} ev Event object
                         */
                        this.fire("collapse" , e);
                    }
                    parent.removeClass(CSS_CLEARED);
                    parent.toggleClass(CSS_COLLAPSED);
                }
            }            
        });
        
        Y.namespace("IC");
        Y.IC.ManageTreeview = TreeviewLite;

    },
    "@VERSION@",
    {
        requires: [
            "ic-manage-plugin-treeview-css"
        ]
    }
);
