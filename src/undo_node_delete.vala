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

public class UndoNodeDelete : UndoItem {

  DrawArea _da;
  Node     _node;
  Node?    _parent;
  int      _index;
  Layout   _layout;

  /* Default constructor */
  public UndoNodeDelete( DrawArea da, Node n, Layout layout ) {
    base( _( "Delete Node" ) );
    _da     = da;
    _node   = n;
    _parent = n.parent;
    _index  = n.index();
    _layout = layout;
  }

  /* Undoes a node deletion */
  public override void undo() {
    _node.attach( _parent, _index, _layout );
    _da.queue_draw();
  }

  /* Redoes a node deletion */
  public override void redo() {
    _node.detach( _layout );
    _da.queue_draw();
  }

}
