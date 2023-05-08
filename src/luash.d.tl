local record sh
   noReset: function(str: string): string
   metamethod __call: function(_: sh, str: string): string
end

return sh