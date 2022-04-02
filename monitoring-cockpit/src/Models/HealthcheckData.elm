module Models.HealthcheckData exposing (..)

import Json.Decode as Decode exposing (Decoder, field, string)


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


type HealthcheckField
    = StringField String
    | NumericField Int
    | BooleanField Bool


healthcheckDataResponseDecoder : Decoder (List HealthcheckRoot)
healthcheckDataResponseDecoder =
    field "healthcheckResponse" healthcheckRootDataListDecoder


healthcheckRootDataListDecoder : Decoder (List HealthcheckRoot)
healthcheckRootDataListDecoder =
    Decode.list healthcheckRootDataDecoder


healthcheckRootDataDecoder : Decoder HealthcheckRoot
healthcheckRootDataDecoder =
    Decode.map2 HealthcheckRoot
        (field "outcome" healthcheckOutcomeDecoder)
        (field "checks" (Decode.list taskHealthcheckNodeDecoder))


taskHealthcheckNodeDecoder : Decoder HealthcheckNode
taskHealthcheckNodeDecoder =
    Decode.map3 HealthcheckNode
        (field "name" string)
        (field "state" healthcheckOutcomeDecoder)
        (field "data" (Decode.succeed []))


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
