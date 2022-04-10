module Models.HealthcheckData exposing
    ( Healthcheck
    , HealthcheckChartConfig
    , HealthcheckField
    , HealthcheckFieldValue(..)
    , HealthcheckNode
    , HealthcheckOutcome(..)
    , HealthcheckRoot
    , extractNumeric
    , healthcheckDataResponseDecoder
    , isNumericField
    )

import Json.Decode as Decode exposing (Decoder, bool, field, int, string)


type alias Healthcheck =
    { id : String
    , name : String
    , url : String
    , chartConfigs : List HealthcheckChartConfig
    }


type alias HealthcheckChartConfig =
    { healthcheckName : String -- Rename to nodeName
    , fieldname : String
    }


type alias HealthcheckRoot =
    { outcome : HealthcheckOutcome
    , checks : List HealthcheckNode
    }


type alias HealthcheckNode =
    { name : String
    , state : HealthcheckOutcome
    , data : List HealthcheckField
    }


type HealthcheckOutcome
    = UP
    | DOWN
    | UNKNOWN String


type alias HealthcheckField =
    { fieldname : String
    , value : HealthcheckFieldValue
    }


type HealthcheckFieldValue
    = StringField String
    | NumericField Int
    | BooleanField Bool


type HealthcheckFieldType
    = StringFieldType String
    | NumericFieldType String
    | BooleanFieldType String



-- DECODERS


healthcheckDataResponseDecoder : Decoder (List HealthcheckRoot)
healthcheckDataResponseDecoder =
    field "healthcheckResponse" healthcheckRootListDecoder


healthcheckRootListDecoder : Decoder (List HealthcheckRoot)
healthcheckRootListDecoder =
    Decode.list healthcheckRootDecoder


healthcheckRootDecoder : Decoder HealthcheckRoot
healthcheckRootDecoder =
    Decode.map2 HealthcheckRoot
        (field "outcome" healthcheckOutcomeDecoder)
        (field "checks" (Decode.list taskHealthcheckNodeDecoder))


taskHealthcheckNodeDecoder : Decoder HealthcheckNode
taskHealthcheckNodeDecoder =
    Decode.map3 HealthcheckNode
        (field "name" string)
        (field "state" healthcheckOutcomeDecoder)
        (field "data" healthcheckNodeDataDecoder)


healthcheckOutcomeDecoder : Decoder HealthcheckOutcome
healthcheckOutcomeDecoder =
    Decode.string
        |> Decode.andThen
            (\outcomeString ->
                case outcomeString of
                    "UP" ->
                        Decode.succeed UP

                    "DOWN" ->
                        Decode.succeed DOWN

                    _ ->
                        Decode.succeed (UNKNOWN outcomeString)
             -- Maybe use Decode.fail?
            )


healthcheckNodeDataDecoder : Decoder (List HealthcheckField)
healthcheckNodeDataDecoder =
    Decode.keyValuePairs decodeStuff
        |> Decode.map
            (List.map
                (\( key, value ) ->
                    HealthcheckField key value
                )
            )


decodeStuff : Decoder HealthcheckFieldValue
decodeStuff =
    Decode.oneOf [ decodeInt, decodeString, decodeBoolean ]



-- Decode.map List.singleton (healthcheckNodeDataFieldDecoder (NumericFieldType "itemCount"))


decodeInt : Decoder HealthcheckFieldValue
decodeInt =
    Decode.map NumericField int


decodeString : Decoder HealthcheckFieldValue
decodeString =
    Decode.map StringField string


decodeBoolean : Decoder HealthcheckFieldValue
decodeBoolean =
    Decode.map BooleanField bool


healthcheckNodeDataFieldListDecoder : List (Decoder HealthcheckField) -> Decoder HealthcheckField
healthcheckNodeDataFieldListDecoder decoders =
    Decode.oneOf decoders



-- healthcheckNodeDataFieldDecoder : HealthcheckFieldType -> Decoder HealthcheckField
-- healthcheckNodeDataFieldDecoder fieldType =
--     case fieldType of
--         StringFieldType fieldName ->
--             Decode.map StringField (field fieldName string)
--
--         NumericFieldType fieldName ->
--             Decode.map NumericField (field fieldName int)
--
--         BooleanFieldType fieldName ->
--             Decode.map BooleanField (field fieldName bool)
-- Functions: Maybe move somewhere else at some point?


extractNumeric : HealthcheckField -> Int
extractNumeric field =
    case field.value of
        NumericField val ->
            val

        _ ->
            -1


isNumericField : HealthcheckField -> Bool
isNumericField field =
    case field.value of
        NumericField _ ->
            True

        _ ->
            False
