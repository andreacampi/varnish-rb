require 'varnish'
require 'ffi'

module Varnish
  module VSL
    extend FFI::Library
    ffi_lib Varnish::LIBVARNISHAPI

    enum :vsl_tag, [
      :debug,
      :error,
      :cli,
      :statsess,
      :reqend,
      :sessionopen,
      :sessionclose,
      :backendopen,
      :backendxid,
      :backendreuse,
      :backendclose,
      :httpgarbage,
      :backend,
      :length,

      :fetcherror,

      :rxrequest,
      :rxresponse,
      :rxstatus,
      :rxurl,
      :rxprotocol,
      :rxheader,

      :txrequest,
      :txresponse,
      :txstatus,
      :txurl,
      :txprotocol,
      :txheader,

      :objrequest,
      :objresponse,
      :objstatus,
      :objurl,
      :objprotocol,
      :objheader,

      :lostheader,

      :ttl,
      :fetch_body,
      :vcl_acl,
      :vcl_call,
      :vcl_trace,
      :vcl_return,
      :vcl_error,
      :reqstart,
      :hit,
      :hitpass,
      :expban,
      :expkill,
      :workthread,

      :esi_xmlerror,

      :hash,

      :backend_health,
      :vcl_log,

      :gzip

      ]

    callback :VSL_handler_f, [:pointer, :vsl_tag, :int, :int, :int, :pointer, :int64], :int

    attach_function 'VSL_Setup',    [ :pointer ], :void
    attach_function 'VSL_Open',     [ :pointer, :int ], :int
    attach_function 'VSL_Dispatch', [ :pointer, :VSL_handler_f, :pointer ], :int
  end
end
