/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;
using Gdk;
using Granite.Widgets;

public class NodeInspector : Stack {

  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private TextView    _name;
  private Switch      _task;
  private Switch      _fold;
  private Box         _link_box;
  private ColorButton _link_color;
  private TextView    _note;
  private DrawArea    _da;
  private Button      _detach_btn;
  private string      _orig_note = "";
  private Node?       _node = null;
  private EventBox    _image_area;
  private Image       _image;
  private Button      _image_btn;
  private Label       _image_loc;
  private bool        _ignore_name_change = false;

  public NodeInspector( DrawArea da ) {

    _da = da;

    /* Set the transition duration information */
    transition_duration = 500;
    transition_type     = StackTransitionType.OVER_DOWN_UP;

    var empty_box = new Box( Orientation.VERTICAL, 10 );
    var empty_lbl = new Label( _( "<big>Select a node to view/edit information</big>" ) );
    var node_box  = new Box( Orientation.VERTICAL, 10 );

    empty_lbl.use_markup = true;
    empty_box.pack_start( empty_lbl, true, true );

    add_named( node_box,  "node" );
    add_named( empty_box, "empty" );

    /* Create the node widgets */
    create_title( node_box );
    create_task( node_box );
    create_fold( node_box );
    create_link( node_box );
    create_note( node_box );
    create_image( node_box );
    create_buttons( node_box );

    _da.node_changed.connect( node_changed );
    _da.theme_changed.connect( theme_changed );

    show_all();

  }

  /* Returns the width of this window */
  public int get_width() {
    return( 300 );
  }

  /* Creates the name entry */
  private void create_title( Box bbox ) {

    Box   box = new Box( Orientation.VERTICAL, 10 );
    Label lbl = new Label( _( "<b>Title</b>" ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _name = new TextView();
    _name.set_wrap_mode( Gtk.WrapMode.WORD );
    _name.buffer.text = "";
    _name.buffer.changed.connect( name_changed );
    _name.focus_out_event.connect( name_focus_out );

    box.pack_start( lbl,   true, false );
    box.pack_start( _name, true, false );

    bbox.pack_start( box, false, true );

  }

  /* Creates the task UI elements */
  private void create_task( Box bbox ) {

    var box  = new Box( Orientation.HORIZONTAL, 0 );
    var lbl  = new Label( _( "<b>Task</b>" ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _task = new Switch();
    _task.button_release_event.connect( task_changed );

    box.pack_start( lbl,   false, true, 0 );
    box.pack_end(   _task, false, true, 0 );

    bbox.pack_start( box, false, true );

  }

  /* Creates the fold UI elements */
  private void create_fold( Box bbox ) {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "<b>Fold</b>" ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _fold = new Switch();
    _fold.button_release_event.connect( fold_changed );

    box.pack_start( lbl,   false, true, 0 );
    box.pack_end(   _fold, false, true, 0 );

    bbox.pack_start( box, false, true );

  }

  /*
   Allows the user to select a different color for the current link
   and tree.
  */
  private void create_link( Box bbox ) {

    _link_box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl   = new Label( _( "<b>Link Color</b>" ) );

    _link_box.homogeneous = true;
    lbl.xalign            = (float)0;
    lbl.use_markup        = true;

    _link_color = new ColorButton();
    _link_color.color_set.connect(() => {
      _da.change_current_link_color( _link_color.rgba );
    });

    _link_box.pack_start( lbl,         false, true, 0 );
    _link_box.pack_end(   _link_color, true,  true, 0 );

    bbox.pack_start( _link_box, false, true );

  }

  /* Creates the note widget */
  private void create_note( Box bbox ) {

    Box   box = new Box( Orientation.VERTICAL, 10 );
    Label lbl = new Label( _( "<b>Note</b>" ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _note = new TextView();
    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );
    _note.focus_in_event.connect( note_focus_in );
    _note.focus_out_event.connect( note_focus_out );

    ScrolledWindow sw = new ScrolledWindow( null, null );
    sw.min_content_width  = 300;
    sw.min_content_height = 100;
    sw.add( _note );

    box.pack_start( lbl, false, false );
    box.pack_start( sw,  true,  true );

    bbox.pack_start( box, true, true );

  }

  /* Creates the image widget */
  private void create_image( Box bbox ) {

    var box = new Box( Orientation.VERTICAL, 0 );
    var lbl = new Label( _( "<b>Image</b>" ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _image_btn = new Button.with_label( _( "Add Image…" ) );
    _image_btn.visible = true;
    _image_btn.clicked.connect( image_button_clicked );

    _image = new Image();

    var btn_edit = new Button.from_icon_name( "document-edit-symbolic" );
    btn_edit.set_tooltip_text( _( "Edit Image" ) );
    btn_edit.clicked.connect(() => {
      _da.edit_current_image();
    });

    var btn_del = new Button.from_icon_name( "edit-delete-symbolic" );
    btn_del.set_tooltip_text( _( "Remove Image" ) );
    btn_del.clicked.connect(() => {
      _da.delete_current_image();
    });

    var btn_box = new Box( Orientation.HORIZONTAL, 20 );
    btn_box.halign       = Align.END;
    btn_box.valign       = Align.START;
    btn_box.border_width = 5;
    btn_box.pack_start( btn_edit, false, false );
    btn_box.pack_start( btn_del,  false, false );

    var reveal_box = new Revealer();
    reveal_box.transition_duration = 500;
    reveal_box.transition_type     = RevealerTransitionType.CROSSFADE;
    reveal_box.add( btn_box );

    var img_overlay = new Overlay();
    img_overlay.add_overlay( reveal_box );
    img_overlay.add( _image );

    _image_area = new EventBox();
    _image_area.visible = false;
    _image_area.add_events( EventMask.ENTER_NOTIFY_MASK | EventMask.LEAVE_NOTIFY_MASK );
    _image_area.enter_notify_event.connect((e) => {
      reveal_box.reveal_child = true;
      return( false );
    });
    _image_area.leave_notify_event.connect((e) => {
      reveal_box.reveal_child = false;
      return( false );
    });
    _image_area.add( img_overlay );

    _image_loc = new Label( "" );
    _image_loc.visible    = false;
    _image_loc.use_markup = true;
    _image_loc.wrap       = true;
    _image_loc.max_width_chars = 40;
    _image_loc.activate_link.connect( image_link_clicked );

    box.pack_start( lbl,         false, false );
    box.pack_start( _image_btn,  false, false );
    box.pack_start( _image_area, true,  true );
    box.pack_start( _image_loc,  false, true );

    bbox.pack_start( box, false, true );

    /* Set ourselves up to be a drag target */
    Gtk.drag_dest_set( _image, DestDefaults.MOTION | DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY );

    _image.drag_data_received.connect((ctx, x, y, data, info, t) => {
      if( data.get_uris().length == 1 ) {
        if( _da.update_current_image( data.get_uris()[0] ) ) {
          Gtk.drag_finish( ctx, true, false, t );
        }
      }
    });

  }

  /* Called when the user clicks on the image button */
  private void image_button_clicked() {

    _da.add_current_image();

  }

  /* Sets the visibility of the image widget to the given value */
  private void set_image_visible( bool show ) {

    _image_btn.visible  = !show;
    _image_area.visible = show;
    _image_loc.visible  = show;

  }

  /* Called if the user clicks on the image URI */
  private bool image_link_clicked( string uri ) {

    File file = File.new_for_uri( uri );

    /* If the URI is a file on the local filesystem, view it with the Files app */
    if( file.get_uri_scheme() == "file" ) {
      var files = AppInfo.get_default_for_type( "inode/directory", true );
      var list  = new List<File>();
      list.append( file );
      try {
        files.launch( list, null );
      } catch( Error e ) {
        return( false );
      }
      return( true );
    }

    return( false );

  }

  /* Creates the node editing button grid and adds it to the popover */
  private void create_buttons( Box bbox ) {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 5;

    var copy_btn = new Button.from_icon_name( "edit-copy-symbolic", IconSize.SMALL_TOOLBAR );
    copy_btn.set_tooltip_text( _( "Copy Node To Clipboard" ) );
    copy_btn.clicked.connect( node_copy );

    var cut_btn = new Button.from_icon_name( "edit-cut-symbolic", IconSize.SMALL_TOOLBAR );
    cut_btn.set_tooltip_text( _( "Cut Node To Clipboard" ) );
    cut_btn.clicked.connect( node_cut );

    /* Create the detach button */
    _detach_btn = new Button.from_icon_name( "minder-detach-symbolic", IconSize.SMALL_TOOLBAR );
    _detach_btn.set_tooltip_text( _( "Detach Node" ) );
    _detach_btn.clicked.connect( node_detach );

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
    del_btn.set_tooltip_text( _( "Delete Node" ) );
    del_btn.clicked.connect( node_delete );

    /* Add the buttons to the button grid */
    grid.attach( copy_btn,    0, 0, 1, 1 );
    grid.attach( cut_btn,     1, 0, 1, 1 );
    grid.attach( _detach_btn, 2, 0, 1, 1 );
    grid.attach( del_btn,     3, 0, 1, 1 );

    /* Add the button grid to the popover */
    bbox.pack_start( grid, false, true );

  }

  /*
   Called whenever the node name is changed within the inspector.
  */
  private void name_changed() {
    if( !_ignore_name_change ) {
      _da.change_current_node_name( _name.buffer.text );
    }
    _ignore_name_change = false;
  }

  /*
   Called whenever the node title loses input focus. Updates the
   node title in the canvas.
  */
  private bool name_focus_out( EventFocus e ) {
    _da.change_current_node_name( _name.buffer.text );
    return( false );
  }

  /* Called whenever the task enable switch is changed within the inspector */
  private bool task_changed( Gdk.EventButton e ) {
    Node? current = _da.get_current_node();
    if( current != null ) {
      _da.change_current_task( !current.task_enabled(), false );
    }
    return( false );
  }

  /* Called whenever the fold switch is changed within the inspector */
  private bool fold_changed( Gdk.EventButton e ) {
    Node? current = _da.get_current_node();
    if( current != null ) {
      _da.change_current_fold( !current.folded );
    }
    return( false );
  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    _da.change_current_node_note( _note.buffer.text );
  }

  /* Saves the original version of the node's note so that we can */
  private bool note_focus_in( EventFocus e ) {
    _node      = _da.get_current_node();
    _orig_note = _note.buffer.text;
    return( false );
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private bool note_focus_out( EventFocus e ) {
    if( (_node != null) && (_node.note != _orig_note) ) {
      _da.undo_buffer.add_item( new UndoNodeNote( _node, _orig_note ) );
    }
    return( false );
  }

  /* Copies the current node to the clipboard */
  private void node_copy() {
    _da.copy_node_to_clipboard();
  }

  /* Cuts the current node to the clipboard */
  private void node_cut() {
    _da.cut_node_to_clipboard();
  }

  /* Detaches the current node and makes it a parent node */
  private void node_detach() {
    _da.detach();
    _detach_btn.set_sensitive( false );
  }

  /* Deletes the current node */
  private void node_delete() {
    _da.delete_node();
  }

  /* Grabs the input focus on the name entry */
  public void grab_name() {
    _name.grab_focus();
  }

  /* Grabs the focus on the note widget */
  public void grab_note() {
    _note.grab_focus();
  }

  /* Called whenever the theme is changed */
  private void theme_changed() {

    int    num_colors = _da.get_theme().num_link_colors();
    RGBA[] colors     = new RGBA[num_colors];

    /* Gather the theme colors into an RGBA array */
    for( int i=0; i<num_colors; i++ ) {
      colors[i] = _da.get_theme().link_color( i );
    }

    /* Clear the palette */
    _link_color.add_palette( Orientation.HORIZONTAL, 10, null );

    /* Set the palette with the new theme colors */
    _link_color.add_palette( Orientation.HORIZONTAL, 10, colors );

  }

  /* Called whenever the user changes the current node in the canvas */
  private void node_changed() {

    Node? current = _da.get_current_node();

    if( current != null ) {
      _ignore_name_change = true;
      _name.buffer.text = current.name.text;
      _task.set_active( current.task_enabled() );
      if( current.is_leaf() ) {
        _fold.set_active( false );
        _fold.set_sensitive( false );
      } else {
        _fold.set_active( current.folded );
        _fold.set_sensitive( true );
      }
      if( current.is_root() ) {
        _link_box.visible = false;
      } else {
        _link_box.visible = true;
        _link_color.rgba  = current.link_color;
        _link_color.alpha = 65535;
      }
      _detach_btn.set_sensitive( current.parent != null );
      _note.buffer.text = current.note;
      if( current.image != null ) {
        var url = _da.image_manager.get_uri( current.image.id ).replace( "&", "&amp;" );
        var str = "<a href=\"" + url + "\">" + url + "</a>";
        current.image.set_image( _image );
        _image_loc.label = str;
        set_image_visible( true );
      } else {
        set_image_visible( false );
      }
      set_visible_child_name( "node" );
    } else {
      set_visible_child_name( "empty" );
    }

  }

}
