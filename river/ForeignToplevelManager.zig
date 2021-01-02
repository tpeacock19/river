// This file is part of river, a dynamic tiling wayland compositor.
//
// Copyright 2020 The River Developers
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

const Self = @This();

const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const util = @import("util.zig");

const Seat = @import("Seat.zig");
const Server = @import("Server.zig");
const View = @import("View.zig");

server: *Server,

manager: *wlr.ForeignToplevelManagerV1,

// zig fmt: off
activate: wl.Listener(*wlr.ForeignToplevelManagerV1.event.Activate) =
    wl.Listener(*wlr.ForeignToplevelManagerV1.event.Activate).init(handleActivate),
fullscreen: wl.Listener(*wlr.ForeignToplevelManagerV1.event.Fullscreen) =
    wl.Listener(*wlr.ForeignToplevelManagerV1.event.Fullscreen).init(handleFullscreen),
close: wl.Listener(*wlr.ForeignToplevelManagerV1.event.Close) =
    wl.Listener(*wlr.ForeignToplevelManagerV1.event.Close).init(handleClose),
// zig fmt: on

pub fn init(self: *Self, server: *Server) !void {
    self.* = .{
        .server = server,
        .manager = try wlr.ForeignToplevelManagerV1.create(server.wl_server),
    };

    self.manager.events.request_activate.add(&self.activate);
    self.manager.events.request_fullscreen.add(&self.fullscreen);
    self.manager.events.request_close.add(&self.close);
}

/// Only honors the request if the view is already visible on the seat's
/// currently focused output. TODO: consider allowing this request to switch
/// output/tag focus.
fn handleActivate(
    listener: *wl.Listener(*wlr.ForeignToplevelManagerV1.event.Activate),
    event: *wlr.ForeignToplevelManagerV1.event.Activate,
) void {
    const view = @intToPtr(*View, event.toplevel.data);
    const seat = @intToPtr(*Seat, event.seat.data);
    seat.focus(view);
    view.output.root.startTransaction();
}

fn handleFullscreen(
    listener: *wl.Listener(*wlr.ForeignToplevelManagerV1.event.Fullscreen),
    event: *wlr.ForeignToplevelManagerV1.event.Fullscreen,
) void {
    const view = @intToPtr(*View, event.toplevel.data);
    view.pending.fullscreen = event.fullscreen;
    view.applyPending();
}

fn handleClose(
    listener: *wl.Listener(*wlr.ForeignToplevelManagerV1.event.Close),
    event: *wlr.ForeignToplevelManagerV1.event.Close,
) void {
    const view = @intToPtr(*View, event.toplevel.data);
    view.close();
}
