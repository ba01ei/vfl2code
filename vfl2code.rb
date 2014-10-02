#!/usr/bin/env ruby


class UIView
    # r means right, b means bottom
    # xref means reference object for x. e.g. [v1]-10-[v2] makes v2.xref=v1, v2.x=10 if v1's size is unknown
    attr_accessor :name, :x, :y, :r, :b, :w, :h, :xref, :yref, :rref, :bref, :added_to_list, :centerx, :centery

    def code_for_x
        return "#{self.xref.to_s.length>0 ? "CGRectGetMaxX(#{self.xref}.frame)+" : ""}#{self.x}"
    end

    def code_for_right
        return "#{self.rref.to_s.length>0 ? "CGRectGetMinX(#{self.rref}.frame)" : "superview.bounds.size.width"}-(#{self.r})"
    end

    def code_for_y
        return "#{self.yref.to_s.length>0 ? "CGRectGetMaxY(#{self.yref}.frame)+" : ""}#{self.y}"
    end

    def code_for_bottom
        return "#{self.bref.to_s.length>0 ? "CGRectGetMinY(#{self.bref}.frame)" : "superview.bounds.size.height"}-(#{self.b})"
    end
end

PARAMS = {:VFL => ""}
HASH = {}
LIST = []

#common beginnings and endings of VFL block comment delimiters (ie // --- VFL... )
STARTS_AND_ENDS = [
    ["\/\/ \-\-\- VFL", "VFL \-\-\-\n"],
    ["\/\/ VFL begin", "\/\/ VFL end\n"],
    ["\/\/ begin VFL", "\/\/ end VFL\n"]
]

def get_or_create_view(name)
    if HASH[name]
        return HASH[name]
    else
        view = UIView.new
        view.name = name
        view.added_to_list = false
        HASH[name] = view
        return view
    end
end

def exists(v)
    unless v
        return false
    end
    return v.length > 0
end

def parse(vfl)

    simpler_vfl = vfl.strip
    # make parsing simpler
    simpler_vfl.gsub! "|[", "|-["
    simpler_vfl.gsub! "][", "]-["
    simpler_vfl.gsub! "]|", "]-|"

    PARAMS[:VFL] = vfl

    lines = simpler_vfl.split("\n")
    lines.each do |line|
        line.strip!
        if line.index("V:")==0
            orientation = :vertical
        else
            orientation = :horizontal
        end

        if line[/center\[([a-zA-Z0-9_\.]+)\s*(?:\(([a-zA-Z\d]+)[^\)]*\))?\]/]
            view = get_or_create_view($1)
            if orientation == :horizontal
                view.centerx = true
                view.w = $2 if $2
            else
                view.centery = true
                view.h = $2 if $2
            end
            next
        end

        # puts orientation.to_s
        line.gsub!(/^(H|V):/, "")
        elements = line.split("-")

        position = "" # positon=empty string means position is unknown. If it's unknown we don't allow any calculation on that
        ref = ""

        treat_element = lambda { |element,reversed|
            # puts "element: #{element}"
            if element == "|"
                position = "0"
            elsif element[/^([_a-zA-Z\d]+).*/]
                # get number between elements
                if exists(position)
                    position = position + "+" + $1
                end
            elsif element[/\[([a-zA-Z0-9_\.]+)\s*(?:\(([_a-zA-Z\d\>]+)[^\)]*\))?\]/]
                # get element in brackets (possibly with number in paren)
                view = get_or_create_view($1)
                # puts "treatint #{view.name}"
                if orientation == :horizontal
                    if reversed
                        view.r = position
                        view.rref = ref
                        # puts "setting the right of #{element} to #{position}, ref is #{ref}."
                    else
                        view.x = position
                        view.xref = ref
                        # puts "setting the left of #{element} to #{position}, ref is #{ref}."
                    end
                    if $2 and (not $2.index(">"))
                        view.w = $2
                        if exists(position)
                            position = position + "+" + view.w
                        end
                        # puts "#{element} does have a width: #{$2}, position becomes #{position}."
                    elsif (not $2) and exists(position)
                        ref = view.name
                        position = "0"
                        # puts "#{element} doesn't have a width, position becomes 0 and ref becomes #{ref}."
                    else
                        position = ""
                        # puts "#{element} has no width and can't determine the edge"
                    end
                else  # vertical
                    if reversed
                        view.b = position
                        view.bref = ref
                    else
                        view.y = position
                        view.yref = ref
                    end
                    if $2 and (not $2.index(">"))
                        view.h = $2
                        if exists(position)
                            position = position + "+" + $2
                        end
                    elsif (not $2) and exists(position)
                        ref = view.name
                        position = "0"
                    else
                        position = ""
                    end
                end
            end
            # puts "position becomes #{position}"
        }
        # puts "regular direction (l->r or top->bottom)"
        elements.each_with_index do |element, idx|
            treat_element.call(element, false)
        end

        # puts "reversed direction (r->l or bottom->top)"
        position = ""
        ref = ""
        elements.reverse.each_with_index do |element, idx|
            treat_element.call(element, true)
        end
    end
    # puts "hash:\n#{HASH}"
end

def add_to_list(position, view)
    unless view
        return
    end
    if view.added_to_list
        return
    end
    LIST.insert(position, view)
    view.added_to_list = true
    if view.xref.to_s.length>0 and view.x.to_s.length>0
        v2 = HASH[view.xref]
        # puts "#{view.name} depends on #{v2.name} coz xref, so before adding #{v2.name} before #{view.name}"
        add_to_list(LIST.index(view), v2)
    end
    if view.yref.to_s.length>0 and view.y.to_s.length>0
        v2 = HASH[view.yref]
        # puts "#{view.name} depends on #{v2.name} coz xref, so before adding #{v2.name} before #{view.name}"
        add_to_list(LIST.index(view), v2)
    end
    if view.rref.to_s.length>0 and view.r.to_s.length>0
        v2 = HASH[view.rref]
        # puts "#{view.name} depends on #{v2.name} coz rref, so before adding #{v2.name} before #{view.name}"
        add_to_list(LIST.index(view), v2)
    end
    if view.bref.to_s.length>0 and view.b.to_s.length>0
        v2 = HASH[view.bref]
        # puts "#{view.name} depends on #{v2.name} coz bref, so before adding #{v2.name} before #{view.name}"
        add_to_list(LIST.index(view), v2)
    end
end

def construct_list
    HASH.each {|k, v|
        # puts "adding #{k} currently it's #{LIST.collect{|v| v.name}.join("-")}"
        add_to_list(LIST.length, v)
    }
    # puts LIST.collect{|v| v.name}
end

def code_gen(swift, idx)
    frame = "f#{idx}"
    flexiblePrefix = swift ? "UIViewAutoresizing.Flexible" : "UIViewAutoresizingFlexible"
    code = "// begin VFL\n"
    code << "/*\n"
    code << PARAMS[:VFL].split("\n").collect{|l| " "+l.strip}.join("\n")
    if swift
      code << "\n */\nvar #{frame}:CGRect;"
    else
      code << "\n */\n{"
      code << "CGRect #{frame};"
    end
    arh = "" # horizontal autoresizing mask
    arv = ""
    LIST.each { |view|
        code << "#{frame}=#{view.name}.frame;" # in case user had predefined sizes, or autocalculated sizes
        if view.centerx
            code << (exists(view.w) ? "#{frame}.size.width=#{view.w};" : "")
            code << "#{frame}.origin.x=(superview.bounds.size.width-#{frame}.size.width)/2.0;"
            arh = "#{flexiblePrefix}LeftMargin|#{flexiblePrefix}RightMargin"
        elsif exists(view.x) and exists(view.w)
            code << "#{frame}.origin.x=#{view.code_for_x};"
            code << "#{frame}.size.width=#{view.w};"
            arh = "#{flexiblePrefix}RightMargin"
        elsif exists(view.w) and exists(view.r)
            code << "#{frame}.origin.x=#{view.code_for_right}-(#{view.w});"
            code << "#{frame}.size.width=#{view.w};"
            arh = "#{flexiblePrefix}LeftMargin"
        elsif exists(view.x) and exists(view.r)
            code << "#{frame}.origin.x=#{view.code_for_x};"
            code << "#{frame}.size.width=#{view.code_for_right}-#{frame}.origin.x;"
            arh = "#{flexiblePrefix}Width"
        else
            arh = ""
            if exists(view.w)
                code << "#{frame}.size.width=#{view.w};"
                arh = "?"
            end
            if exists(view.x)
                code << "#{frame}.origin.x=#{view.code_for_x};"
                arh = "#{flexiblePrefix}RightMargin"
            end
            if exists(view.r)
                code << "#{frame}.origin.x=#{view.code_for_right}-#{frame}.size.width;"
                arh = "#{flexiblePrefix}LeftMargin"
            end
            if arh.length==0
                arh = "?"
            end
        end

        if view.centery
            code << (exists(view.h) ? "#{frame}.size.height=#{view.h};" : "")
            code << "#{frame}.origin.y=(superview.bounds.size.height-#{frame}.size.height)/2.;"
            arv = "#{flexiblePrefix}TopMargin|#{flexiblePrefix}BottomMargin"
        elsif exists(view.y) and exists(view.h)
            code << "#{frame}.origin.y=#{view.code_for_y};"
            code << "#{frame}.size.height=#{view.h};"
            arv = "#{flexiblePrefix}BottomMargin"
        elsif exists(view.h) and exists(view.b)
            code << "#{frame}.origin.y=#{view.code_for_bottom}-#{view.h};"
            code << "#{frame}.size.height=#{view.h};"
            arv = "#{flexiblePrefix}TopMargin"
        elsif exists(view.y) and exists(view.b)
            code << "#{frame}.origin.y=#{view.code_for_y};"
            code << "#{frame}.size.height=#{view.code_for_bottom}-#{frame}.origin.y;"
            arv = "#{flexiblePrefix}Height"
        else
            arv = ""
            if exists(view.h)
                code << "#{frame}.size.height=#{view.h};"
                arv = "?"
            end
            if exists(view.y)
                code << "#{frame}.origin.y=#{view.code_for_y};"
                arv = "#{flexiblePrefix}BottomMargin"
            end
            if exists(view.b)
                code << "#{frame}.origin.y=#{view.code_for_bottom}-#{frame}.size.height;"
                arv = "#{flexiblePrefix}TopMargin"
            end
            if arv.length==0
                arv = "?"
            end
        end

        code << "#{view.name}.frame=#{frame};"
        code << (arh=="?" ? "" : "#{view.name}.autoresizingMask|=#{arh};")
        code << (arv=="?" ? "" : "#{view.name}.autoresizingMask|=#{arv};")
        if swift
          code << "superview.addSubview(#{view.name});"
        else
          code << "[superview addSubview:#{view.name}];"
        end
    }
    unless swift
      code << "}"
    end
    code << "\n// end VFL\n"
    code
end


def transform_raw_code(vfl, swift, idx)
    PARAMS[:VFL] = ""
    HASH.clear
    LIST.clear

    parse(vfl)
    construct_list
    code_gen(swift, idx)
end

def transform_delimited_code(input, swift)
    code = input
    vfl_start = "/*\n"
    vfl_finish = "*/"
    last_i_finish = 0

    idx = 0
    STARTS_AND_ENDS.each do |start, finish|
        $stderr.puts "checking blocks between #{start} and #{finish}"
        last_i_finish = 0
        while true do
            i_start = code.index(start, last_i_finish)
            break unless i_start
            i_finish = code.index(finish, i_start)
            break unless i_finish
            last_i_finish = i_finish
            $stderr.puts "detected block: #{i_start} - #{i_finish}" if $stdout.isatty
            i_vfl_start = code.index(vfl_start, i_start)
            i_vfl_end = code.index(vfl_finish, i_vfl_start)
            $stderr.puts "vfl: #{i_vfl_start} - #{i_vfl_end}" if $stdout.isatty
            vfl =  code[i_vfl_start+vfl_start.length..i_vfl_end-1]

            # $stderr.puts "transform raw code: idx=#{idx}, vfl.strip:#{vfl.strip}"
            newcode = transform_raw_code(vfl.strip, swift, idx)
            idx += 1

            # find indent
            indent = ""
            i = i_start - 1
            while code[i..i]!="\n"  do
                indent = code[i..i] + indent
                i = i - 1
            end

            lines = newcode.split("\n")
            newcode = ""
            lines.each_with_index {|line, idx|
                if idx==0 or line.strip.length==0
                    newcode << line + "\n"
                else
                    newcode << (indent + line) + "\n"
                end
            }
            code[i_start..i_finish+finish.length-1] = newcode
        end
    end

    code
end

def update_file(path)
    # start = "\/\/ \-\-\- VFL"
    # finish = "VFL \-\-\-\n"
    File.open(path, "r") do |f|
        code = f.read

        code = transform_delimited_code(code, path.index(".swift")!=nil)

        File.open(path, "w") do |f|
            f.write(code)
        end
    end
end


if __FILE__ == $0
    if ARGV[0]=="-h"
        $stderr.puts "Usage: #{$0} [-r|--raw]|[-f filename]"
        $stderr.puts
        $stderr.puts " -r, --raw     Treat standard input as raw VFL without comment delimiters"
        $stderr.puts " -f filename   Transform a file IN PLACE"
        $stderr.puts
        $stderr.puts "With no file specified, will transform standard input and output to standard output"
    elsif ARGV[0]=="-f"
        update_file(ARGV[1])
    else
        mode = :delimited
        swift = false
        for arg in ARGV
          if ["-r", "--raw"].index(arg)
            mode = :raw
          elsif ["-s", "--swift"].index(arg)
            swift = true
          end
        end

        str = STDIN.read
        if mode == :raw
            puts transform_raw_code(str, swift, 0)
        else
            puts transform_delimited_code(str, swift)
        end
    end
end
