require 'varnish'
require 'ffi'

module Varnish
  module VSM
    extend FFI::Library
    ffi_lib Varnish::LIBVARNISHAPI

    attach_function 'VSM_New', [], :pointer
    attach_function 'VSM_n_Arg', [:pointer, :string], :int
  end
end
