require 'bacon'
require 'bacon/rr'

DEVELOPMENT_MODE = true

require_relative '../lib/smash_and_grab/log'
SmashAndGrab::Log.level = :ERROR # Don't print out junk.

require_relative '../lib/smash_and_grab'

module Bacon
  class Context
    attr_accessor :described

    alias_method :old_initialize, :initialize
    def initialize(name, &block)
      old_initialize(name, &block)

      @subject_block = nil
      @subject = nil
      @described = nil
    end

    def describe(*args, &block)
      context = Bacon::Context.new(args.join(' '), &block)
      (parent_context = self).methods(false).each {|e|
        class<<context; self end.send(:define_method, e) {|*args| parent_context.send(e, *args)}
      }

      context.described = (args.size == 1 and args.first.is_a?(Class)) ? args.first : nil
      context.subject(&@subject_block) if @subject_block

      @before.each { |b| context.before(&b) }
      @after.each { |b| context.after(&b) }

      context.run
    end

    def helper(name, &block)
      before { (class<<self; self; end).send :define_method, name, &block }
    end

    def subject(&block)
      if block_given?
        @subject_block = block
      else
        @subject
      end
    end

    def run_requirement(description, spec)
      Bacon.handle_requirement description do
        begin
          Counter[:depth] += 1
          rescued = false
          begin
            @before.each { |block| instance_eval(&block) }
            @subject = @subject_block ? instance_eval(&@subject_block) : nil
            prev_req = Counter[:requirements]
            instance_eval(&spec)
          rescue Object => e
            rescued = true
            raise e
          ensure
            if Counter[:requirements] == prev_req and not rescued
              raise Error.new(:missing,
                              "empty specification: #{@name} #{description}")
            end
            begin
              @after.each { |block| instance_eval(&block) }
            rescue Object => e
              raise e  unless rescued
            end
          end
        rescue Object => e
          ErrorLog << "#{e.class}: #{e.message}\n"
          e.backtrace.find_all { |line| line !~ /bin\/bacon|\/bacon\.rb:\d+/ }.
              each_with_index { |line, i|
            ErrorLog << "\t#{line}#{i==0 ? ": #@name - #{description}" : ""}\n"
          }
          ErrorLog << "\n"

          if e.kind_of? Error
            Counter[e.count_as] += 1
            e.count_as.to_s.upcase
          else
            Counter[:errors] += 1
            "ERROR: #{e.class}"
          end
        else
          ""
        ensure
          Counter[:depth] -= 1
        end
      end
    end
  end
end

module Kernel
  private
  def describe(*args, &block)
    context = Bacon::Context.new(args.join(' '), &block)
    context.described = (args.size == 1 and args.first.is_a?(Class)) ? args.first : nil
    context.subject { described.new }
    context.run
  end
end
