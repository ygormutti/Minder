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

public class QuickEntry : Gtk.Window {

  private TextView _entry;

  public QuickEntry( DrawArea da ) {

    /* Configure the window */
    default_width   = 500;
    default_height  = 500;
    modal           = true;
    deletable       = false;
    title           = _( "Quick Entry" );
    transient_for   = da.win;
    window_position = WindowPosition.CENTER_ON_PARENT;

    /* Add window elements */
    var box = new Box( Orientation.VERTICAL, 0 );

    /* Create the text entry area */
    _entry = new TextView();
    _entry.border_width = 5;
    _entry.set_wrap_mode( Gtk.WrapMode.WORD );
    _entry.key_press_event.connect( on_keypress );

    /* Create the scrolled window for the text entry area */
    var sw = new ScrolledWindow( null, null );
    sw.add( _entry );

    var helprev    = new Revealer();
    var helpgrid   = new Grid();
    helpgrid.border_width = 5;
    var help_title = make_help_label( _( "Help for inputting node information:" ) + "\n" );
    var help_line  = make_help_label( "  - " + _( "Each line of text describes either the title of a node or note information for a node." ) );
    var help_tab0  = make_help_label( "  - <b>" + _( "Tab" ) + "</b>:" );
    var help_tab1  = make_help_label( "  " + _( "Creates a child node of the previous node." ) );
    var help_hdr0  = make_help_label( "  - <b>#</b>:" );
    var help_hdr1  = make_help_label( "  " + _( "If this character is the first non-whitespace character, makes a new root node from the title that follows." ) );
    var help_node0 = make_help_label( "  - <b>*, - or +</b>:" );
    var help_node1 = make_help_label( "  " + _( "If this character is the first non-whitespace character, make a new node from the title that follows." ) );
    var help_note0 = make_help_label( "  - <b>&gt;</b>:" );
    var help_note1 = make_help_label( "  " + _( "If this character is the first non-whitespace character, the following line is appended to the previous node's note." ) );
    var help_utsk0 = make_help_label( "  - <b>[ ]</b>:" );
    var help_utsk1 = make_help_label( "  " + _( "If this follows *, + or -, the node is made an uncompleted task." ) );
    var help_ctsk0 = make_help_label( "  - <b>[x] or [X]</b>:" );
    var help_ctsk1 = make_help_label( "  " + _( "If this follows *, + or -, the node is made a completed task." ) );
    helpgrid.attach( help_title, 0, 0, 2 );
    helpgrid.attach( help_line,  0, 1, 2 );
    helpgrid.attach( help_tab0,  0, 2 );
    helpgrid.attach( help_tab1,  1, 2 );
    helpgrid.attach( help_hdr0,  0, 3 );
    helpgrid.attach( help_hdr1,  1, 3 );
    helpgrid.attach( help_node0, 0, 4 );
    helpgrid.attach( help_node1, 1, 4 );
    helpgrid.attach( help_note0, 0, 5 );
    helpgrid.attach( help_note1, 1, 5 );
    helpgrid.attach( help_utsk0, 0, 6 );
    helpgrid.attach( help_utsk1, 1, 6 );
    helpgrid.attach( help_ctsk0, 0, 7 );
    helpgrid.attach( help_ctsk1, 1, 7 );
    helprev.reveal_child = false;
    helprev.add( helpgrid );

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.border_width = 5;

    var info = new Button.from_icon_name( "dialog-information-symbolic", IconSize.BUTTON );
    info.relief = ReliefStyle.NONE;
    info.clicked.connect(() => {
      helprev.reveal_child = !helprev.reveal_child;
    });

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect(() => {
      close();
    });

    var ins = new Button.with_label( _( "Insert" ) );
    ins.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    ins.clicked.connect(() => {
      ExportText.import_text( _entry.buffer.text, 8, da, false );
      close();
    });

    bbox.pack_start( info, false, false );
    bbox.pack_end( ins,    false, false );
    bbox.pack_end( cancel, false, false );

    box.pack_start( sw,      true,  true );
    box.pack_end(   bbox,    false, true );
    box.pack_end(   helprev, false, true );

    add( box );

    show_all();

  }

  private Label make_help_label( string str ) {
    var lbl = new Label( str );
    lbl.use_markup = true;
    lbl.xalign     = (float)0;
    lbl.get_style_context().add_class( "greyed-label" );
    return( lbl );
  }

  private bool on_keypress( EventKey e ) {

    switch( e.keyval ) {
      case 32    :  return( handle_space() );
      case 65293 :  return( handle_return() );
      case 65289 :  return( handle_tab() );
    }

    return( false );

  }

  /* Returns the text from the start of the current line to the current insertion cursor */
  private string get_line_text( int adjust ) {

    TextIter current;
    TextIter startline;
    TextIter endline;
    var      buf = _entry.buffer;

    buf.get_iter_at_mark( out current, buf.get_insert() );

    /* Adjust the line */
    if( adjust < 0 ) {
      current.backward_lines( 0 - adjust );
    } else if( adjust > 0 ) {
      current.backward_lines( adjust );
    }

    buf.get_iter_at_line( out startline, current.get_line() );
    buf.get_iter_at_line( out endline,   current.get_line() + 1 );

    return( buf.get_text( startline, endline, true ) );

  }

  /* Returns the text from the start of the current line to the current insertion cursor */
  private string get_start_to_current_text() {

    TextIter startline;
    TextIter endline;
    var      buf = _entry.buffer;

    /* Get the text on the current line */
    buf.get_iter_at_mark( out endline,   buf.get_insert() );
    buf.get_iter_at_line( out startline, endline.get_line() );

    return( buf.get_text( startline, endline, true ) );

  }

  /* Returns the whitespace at the beginning of the current line */
  private bool get_whitespace( string line, out string wspace ) {

    wspace = "";

    try {

      MatchInfo match_info;
      var       re = new Regex( "^([ \\t]*)" );

      if( re.match( line, 0, out match_info ) ) {
        wspace = match_info.fetch( 1 );
        return( true );
      }

    } catch( RegexError err ) {
      return( false );
    }

    return( false );

  }

  /* Converts the given whitespace to all spaces */
  private string tabs_to_spaces( string wspace ) {

    var tspace = string.nfill( 8, ' ' );

    return( wspace.replace( "\t", tspace ) );

  }

  /* If the user attempts to hit the space bar when adding front-end whitespace, don't insert it */
  private bool handle_space() {

    return( get_start_to_current_text().strip() == "" );

  }

  /* If the return key is pressed, we will automatically indent the next line */
  private bool handle_return() {

    string wspace;

    if( get_whitespace( get_line_text( 0 ), out wspace ) ) {
      var ins = "\n" + wspace;
      _entry.buffer.insert_at_cursor( ins, ins.length );
      return( true );
    }

    return( false );

  }

  /* If the Tab key is pressed, only allow it if it is valid to do so */
  private bool handle_tab() {

    TextIter current;
    var      prev = "";
    var      curr = "";

    _entry.buffer.get_iter_at_mark( out current, _entry.buffer.get_insert() );

    if( current.get_line() == 0 ) {
      return( true );
    } else if( get_whitespace( get_line_text( 0 ), out curr ) && get_whitespace( get_line_text( -1 ), out prev ) ) {
      return( tabs_to_spaces( curr ).length > tabs_to_spaces( prev ).length );
    }

    return( false );

  }

}
