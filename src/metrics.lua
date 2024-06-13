function pinky(a)
    return a.f == 1 or a.f == 10
end

function ring(a)
    return a.f == 2 or a.f == 9
end

function middle(a)
    return a.f == 3 or a.f == 8
end

function index(a)
    return a.f == 4 or a.f == 7
end

function thumb(a)
    return a.f == 5 or a.f == 6
end

function middle_or_ring(a)
    return middle(a) or ring(a)
end

function hand(a)
    return ({1, 1, 1, 1, 1, 2, 2, 2, 2, 2})[a.x]
end

function same_hand(a, b)
    return hand(a) == hand(b)
end

function same_finger(a, b)
    return a.f == b.f
end

function same_row(a, b)
    return math.abs(a.y - b.y) <= .5
end

function horizontal(a, b)
    return math.abs(a.x - b.x)
end

function vertical(a, b)
    return math.abs(a.y - b.y)
end

function adjacent(a, b)
    return (
        not thumb(a) and
        not thumb(b) and
        math.abs(a.f - b.f) == 1
    )
end

function direction(a, b)
    if not same_hand(a, b) or same_finger(a, b) then
        return 0
    else
        return ((-1) ^ hand(a)) * (a.f - b.f) / math.abs(a.f - b.f)
    end
end

function sfr(a, b)
    return (
        a.x == b.x and
        a.y == b.y
    )
end

function sfb(a, b)
    return (
        same_finger(a, b) and
        not sfr(a, b)
    )
end

function lsb(a, b)
    return (
        adjacent(a, b) and
        horizontal(a, b) >= 2
    )
end

function hsb(a, b)
    return (
        not sfb(a, b) and
        same_hand(a, b) and
        vertical(a, b) == 1 and
        middle_or_ring(a.y > b.y and a or b)
    )
end

function fsb(a, b)
    return (
        not sfb(a, b) and
        same_hand(a, b) and
        vertical(a, b) == 2 and
        middle_or_ring(a.y > b.y and a or b)
    )
end

function alternate(a, b, c)
    return (
        not same_hand(a, b) and
        not same_hand(b, c)
    )
end

function roll(a, b, c)
    return (
        not same_hand(a, c) and
        not same_finger(a, b) and
        not same_finger(b, c)
    )
end

function adjacent_roll(a, b, c)
    return roll(a, b, c) and (
        adjacent(a, b) or
        adjacent(b, c)
    )
end

function row_roll(a, b, c)
    return roll(a, b, c) and (
        (same_row(a, b) and same_hand(a, b)) or
        (same_row(b, c) and same_hand(b, c))
    )
end

function inroll(a, b, c)
    return (
        roll(a, b, c) and
        math.max(direction(a, b), direction(b, c)) == 1
    )
end

function outroll(a, b, c)
    return (
        roll(a, b, c) and
        math.min(direction(a, b), direction(b, c)) == -1
    )
end

function redirect(a, b, c)
    return (
        same_hand(a, b) and
        same_hand(b, c) and
        not same_finger(a, b) and
        not same_finger(b, c) and
        direction(a, b) ~= direction(b, c)
    )
end

function onehand(a, b, c)
    return (
        same_hand(a, b) and
        same_hand(b, c) and
        not same_finger(a, b) and
        not same_finger(b, c) and
        direction(a, b) == direction(b, c)
    )
end