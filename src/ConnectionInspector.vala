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

public class ConnectionInspector : Box {

  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private TextView    _title;
  private TextView    _note;
  private DrawArea    _da;
  private string      _orig_note           = "";
  private Connection? _connection          = null;
  private bool        _ignore_title_change = false;

  public ConnectionInspector( DrawArea da ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _da = da;

    /* Create the node widgets */
    create_title();
    create_note();
    create_buttons();

    _da.connection_changed.connect( connection_changed );

    show_all();

  }

  /* Returns the width of this window */
  public int get_width() {
    return( 300 );
  }

  /* Creates the name entry */
  private void create_title() {

    Box   box = new Box( Orientation.VERTICAL, 10 );
    Label lbl = new Label( _( "<b>Title</b>" ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _title = new TextView();
    _title.set_wrap_mode( Gtk.WrapMode.WORD );
    _title.buffer.text = "";
    _title.buffer.changed.connect( title_changed );
    _title.focus_out_event.connect( title_focus_out );

    box.pack_start( lbl,   true, false );
    box.pack_start( _title, true, false );

    pack_start( box, false, true );

  }

  /* Creates the note widget */
  private void create_note() {

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

    pack_start( box, true, true );

  }

  /* Creates the node editing button grid and adds it to the popover */
  private void create_buttons() {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 5;

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
    del_btn.set_tooltip_text( _( "Delete Connection" ) );
    del_btn.clicked.connect( connection_delete );

    /* Add the buttons to the button grid */
    grid.attach( del_btn, 0, 0, 1, 1 );

    /* Add the button grid to the popover */
    pack_start( grid, false, true );

  }

  /*
   Called whenever the node name is changed within the inspector.
  */
  private void title_changed() {
    if( !_ignore_title_change ) {
      _da.change_current_connection_title( _title.buffer.text );
    }
    _ignore_title_change = false;
  }

  /*
   Called whenever the node title loses input focus. Updates the
   node title in the canvas.
  */
  private bool title_focus_out( EventFocus e ) {
    _da.change_current_connection_title( _title.buffer.text );
    return( false );
  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    _da.change_current_connection_note( _note.buffer.text );
  }

  /* Saves the original version of the node's note so that we can */
  private bool note_focus_in( EventFocus e ) {
    _connection = _da.get_current_connection();
    _orig_note  = _note.buffer.text;
    return( false );
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private bool note_focus_out( EventFocus e ) {
    if( (_connection != null) && (_connection.note != _orig_note) ) {
      _da.undo_buffer.add_item( new UndoConnectionNote( _connection, _orig_note ) );
    }
    return( false );
  }

  /* Deletes the current connection */
  private void connection_delete() {
    _da.delete_connection();
  }

  /* Grabs the input focus on the name entry */
  public void grab_title() {
    _title.grab_focus();
  }

  /* Grabs the focus on the note widget */
  public void grab_note() {
    _note.grab_focus();
  }

  /* Called whenever the user changes the current node in the canvas */
  private void connection_changed() {

    Connection? current = _da.get_current_connection();

    if( current != null ) {
      _ignore_title_change = true;
      _title.buffer.text = (current.title != null) ? current.title.text : null;
      _note.buffer.text = current.note;
    }

  }

}
