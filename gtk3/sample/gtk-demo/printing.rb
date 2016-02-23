# Copyright (c) 2016 Ruby-GNOME2 Project Team
# This program is licenced under the same licence as Ruby-GNOME2.
#
=begin
=  Printing/Printing

 GtkPrintOperation offers a simple API to support printing
 in a cross-platform way.

=end
module PrintingDemo
  HEADER_HEIGHT = 10 * 72 / 25.4
  HEADER_GAP = 3 * 72 / 25.4

  def self.run_demo(main_window)
    print_operation = Gtk::PrintOperation.new

    resource_name = File.expand_path(__FILE__)
    font_size = 12.0
    num_pages = 0
    lines_per_page = 0
    lines = []

    print_operation.signal_connect "begin-print" do |operation, context|
      height = context.height - HEADER_HEIGHT - HEADER_GAP
      lines_per_page = (height / font_size).floor
      file = File.open(resource_name, "r")
      file.each_line do |line|
        lines << line
      end
      num_pages = lines.size / (lines_per_page + 1)
      operation.n_pages = num_pages
    end

    print_operation.signal_connect "draw-page" do |_operation, context, page_nr|
      cr = context.cairo_context
      width = context.width
      cr.rectangle(0, 0, width, HEADER_HEIGHT)
      cr.set_source_rgb(0.8, 0.8, 0.8)
      cr.fill_preserve

      cr.set_source_rgb(0, 0, 0)
      cr.line_width = 1
      cr.stroke

      layout = context.create_pango_layout
      desc = Pango::FontDescription.new("sans 14")
      layout.font_description = desc

      layout.text = resource_name
      text_width, text_height = layout.pixel_size

      if text_width > width
        layout.width = width
        layout.ellipsize = :start
        text_width, text_height = layout.pixel_size
      end
      cr.move_to((width - text_width) / 2,
                 (HEADER_HEIGHT - text_height) / 2)
      cr.show_pango_layout(layout)

      layout.text = "#{page_nr + 1}/#{num_pages}"
      layout.width = -1
      text_width, text_height = layout.pixel_size

      cr.move_to(width - text_width - 4,
                 (HEADER_HEIGHT - text_height) / 2)
      cr.show_pango_layout(layout)

      layout = context.create_pango_layout
      desc = Pango::FontDescription.new("monospace")
      desc.size = font_size * Pango::SCALE
      layout.font_description = desc

      cr.move_to(0, HEADER_HEIGHT + HEADER_GAP)
      start_line = page_nr * lines_per_page

      lines[start_line, lines_per_page].each do |line|
        layout.text = line
        cr.show_pango_layout(layout)
        cr.rel_move_to(0, font_size)
      end
    end

    operation.signal_connect "end-print" do
      puts "End of print"
    end

    operation.use_full_page = false
    operation.unit = :points
    operation.embed_page_setup = true

    settings = Gtk::PrintSettings.new
    settings.set(:ouput_basename, "gtk-demo")

    operation.print_settings = settings

    begin
      operation.run(:print_dialog, main_window)
    rescue => error
      dialog = Gtk::MessageDialog.new(:parent => main_window,
                                      :flags => :destroy_with_parent,
                                      :type => :error,
                                      :buttons => :close,
                                      :message => error.message)
      dialog.signal_connect "response" do
        dialog.destroy
      end
      dialog.show
    end
  end
end
