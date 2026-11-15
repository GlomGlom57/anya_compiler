section .imports
    "testing/dummy.al"
    "testing/mrfresh.al"
endsection

section .data
    u8u max 18
    u8u age 22
    u16u t -10
endsection

section .text
    exit:
        end
    start:
        u8r tmpmax
        @loadc max
        @store tmpmax

        prioroff
        @loadc age
        sub tmpmax

        jmpp exit

endsection
