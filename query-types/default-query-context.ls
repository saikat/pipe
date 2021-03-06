require! \moment

module.exports = ->

    # parse-date :: String -> Date
    parse-date = (s) -> new Date s

    # today :: a -> Date
    today = -> ((moment!start-of \day .format "YYYY-MM-DDT00:00:00.000") + \Z) |> parse-date

    # to-timestamp :: String -> Int
    to-timestamp = (s) -> (moment (new Date s)).unix! * 1000

    {
        get-today: today
        moment
        parse-date
        sentiment: require \sentiment
        today: today!
        to-timestamp
    }