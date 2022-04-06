module Main exposing (..)

import Browser
import Chart as Chart
import Chart.Attributes as ChartAttributes
import Html exposing (div, text)
import Html.Attributes exposing (..)
import Http
import Models.HealthcheckData as HealthcheckData
import Svg as Svg



-- MAIN


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


init : () -> ( RootModel, Cmd Msg )
init _ =
    ( { healthcheckData = []
      , httpStatus = Loading
      }
    , Http.get
        { url = "http://localhost:3000/mock-monitoring-backend/api/v1/healthchecks/355c722a-4f1c-42fb-a9a3-4fb11f5a0508/data"
        , expect = Http.expectJson GotTaskHealthcheckData HealthcheckData.healthcheckDataResponseDecoder
        }
    )


type alias RootModel =
    { healthcheckData : List HealthcheckData.HealthcheckRoot
    , httpStatus : HttpStatus
    }


type HttpStatus
    = Success
    | Loading
    | Error Http.Error


type Msg
    = GotTaskHealthcheckData (Result Http.Error (List HealthcheckData.HealthcheckRoot))


subscriptions : RootModel -> Sub Msg
subscriptions rootModel =
    Sub.none



-- UPDATE


update : Msg -> RootModel -> ( RootModel, Cmd Msg )
update (GotTaskHealthcheckData result) rootModel =
    case result of
        Ok healthcheckRoots ->
            ( { rootModel | healthcheckData = healthcheckRoots, httpStatus = Success }, Cmd.none )

        Err error ->
            ( { rootModel | httpStatus = Error error }, Cmd.none )



-- VIEW


view : RootModel -> Html.Html Msg
view rootModel =
    let
        maybeChecks =
            List.map (\root -> List.head root.checks) rootModel.healthcheckData

        checks =
            List.map (Maybe.withDefault { name = "default", state = HealthcheckData.UNKNOWN "defaultErr", data = [] }) maybeChecks

        dataResult =
            healthchecksToData "itemCount" checks
    in
    div []
        [ text (Debug.toString rootModel)
        , case dataResult of
            Ok data ->
                div [ class "healthcheck-chart" ]
                    [ Chart.chart
                        [ ChartAttributes.height 300
                        , ChartAttributes.width 300
                        ]
                        [ Chart.xLabels []
                        , Chart.yLabels [ ChartAttributes.withGrid ]
                        , Chart.labelAt ChartAttributes.middle (ChartAttributes.percent 0) [ ChartAttributes.moveDown 40 ] [ Svg.text "TaskCount" ]
                        , Chart.series Tuple.first
                            [ Chart.interpolated Tuple.first [] []
                            , Chart.interpolated Tuple.second [] []
                            ]
                            (List.map (\( val1, val2 ) -> ( toFloat val1, toFloat val2 )) data)
                        ]
                    ]

            Err error ->
                div [] [ text error ]
        ]


healthchecksToData : String -> List HealthcheckData.HealthcheckNode -> Result String (List ( Int, Int ))
healthchecksToData fieldName nodes =
    let
        healthcheckFieldResults =
            List.map (healthcheckToData fieldName) nodes

        correctHealthcheckFields =
            List.filter isNotError healthcheckFieldResults

        healthcheckFields =
            List.map (Result.withDefault { fieldname = "def", value = HealthcheckData.NumericField -1 }) correctHealthcheckFields
    in
    case List.any isError healthcheckFieldResults of
        True ->
            Err "Contained errors"

        False ->
            case List.all isNumericField healthcheckFields of
                True ->
                    Ok (List.indexedMap Tuple.pair (List.map extractNumeric healthcheckFields))

                False ->
                    Err "Not all numerics"


extractNumeric : HealthcheckData.HealthcheckField -> Int
extractNumeric field =
    case field.value of
        HealthcheckData.NumericField val ->
            val

        _ ->
            -1


isNumericField : HealthcheckData.HealthcheckField -> Bool
isNumericField field =
    case field.value of
        HealthcheckData.NumericField _ ->
            True

        _ ->
            False


healthcheckToData : String -> HealthcheckData.HealthcheckNode -> Result String HealthcheckData.HealthcheckField
healthcheckToData fieldName node =
    let
        maybeHealthcheckField =
            List.head (List.filter (matchesFieldName fieldName) node.data)
    in
    case maybeHealthcheckField of
        Just field ->
            Ok field

        Nothing ->
            Err ("No field found matching name: " ++ fieldName)


isError : Result a b -> Bool
isError result =
    case result of
        Ok _ ->
            False

        Err _ ->
            True


isNotError : Result a b -> Bool
isNotError result =
    not (isError result)


matchesFieldName : String -> HealthcheckData.HealthcheckField -> Bool
matchesFieldName targetFieldname field =
    field.fieldname == targetFieldname


plotData =
    [ { age = 0, x = 40, y = 4 }
    , { age = 5, x = 80, y = 24 }
    , { age = 10, x = 120, y = 36 }
    , { age = 15, x = 180, y = 54 }
    , { age = 20, x = 184, y = 60 }
    ]


healthcheckOutcomeAsString : HealthcheckData.HealthcheckOutcome -> String
healthcheckOutcomeAsString outcome =
    case outcome of
        HealthcheckData.UP ->
            "UP"

        HealthcheckData.DOWN ->
            "DOWN"

        HealthcheckData.UNKNOWN state ->
            "Unbekanntes Ergebnis: " ++ state


httpStatusAsString : HttpStatus -> String
httpStatusAsString status =
    case status of
        Success ->
            "Success"

        Loading ->
            "Loading"

        Error httpError ->
            "Error with message: " ++ Debug.toString httpError
