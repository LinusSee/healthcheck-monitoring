module Main exposing (..)

import Browser
import Chart as Chart
import Chart.Attributes as ChartAttributes
import Dict exposing (Dict)
import Html exposing (button, div, p, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
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
    ( { healthchecks = [ { id = "355c722a-4f1c-42fb-a9a3-4fb11f5a0508", name = "taskdata healthcheck", url = "not yet important" } ]
      , selectedHealthcheckId = Nothing
      , healthcheckData = Dict.empty
      , processedHealthcheckData = Dict.empty
      , httpStatus = Loading
      }
    , Http.get
        { url = "http://localhost:3000/mock-monitoring-backend/api/v1/healthchecks/355c722a-4f1c-42fb-a9a3-4fb11f5a0508/data"
        , expect = Http.expectJson GotTaskHealthcheckData HealthcheckData.healthcheckDataResponseDecoder
        }
    )


type alias RootModel =
    { healthchecks : List HealthcheckData.Healthcheck
    , selectedHealthcheckId : Maybe String
    , healthcheckData : Dict String (List HealthcheckData.HealthcheckRoot)
    , processedHealthcheckData : Dict String (List ( Float, Float ))
    , httpStatus : HttpStatus
    }


type HttpStatus
    = Success
    | Loading
    | Error Http.Error


type Msg
    = GotTaskHealthcheckData (Result Http.Error (List HealthcheckData.HealthcheckRoot))
    | HealthcheckListItemSelected String


subscriptions : RootModel -> Sub Msg
subscriptions rootModel =
    Sub.none



-- UPDATE


update : Msg -> RootModel -> ( RootModel, Cmd Msg )
update msg rootModel =
    case msg of
        GotTaskHealthcheckData result ->
            case result of
                Ok healthcheckRoots ->
                    let
                        maybeChecks =
                            List.map (\root -> List.head root.checks) healthcheckRoots

                        checks =
                            List.map (Maybe.withDefault { name = "default", state = HealthcheckData.UNKNOWN "defaultErr", data = [] }) maybeChecks

                        dataResult =
                            healthchecksToData "itemCount" checks

                        floatData =
                            case dataResult of
                                Ok data ->
                                    List.map (\( val1, val2 ) -> ( toFloat val1, toFloat val2 )) data

                                Err error ->
                                    []
                    in
                    ( { rootModel
                        | healthcheckData = Dict.insert "myKey" healthcheckRoots rootModel.healthcheckData
                        , httpStatus = Success
                        , processedHealthcheckData = Dict.insert "myKey" floatData rootModel.processedHealthcheckData
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { rootModel | httpStatus = Error error }, Cmd.none )

        HealthcheckListItemSelected healthcheckId ->
            ( { rootModel | selectedHealthcheckId = Just healthcheckId }, Cmd.none )



-- VIEW


view : RootModel -> Html.Html Msg
view rootModel =
    div []
        [ viewHealthchecks rootModel.healthchecks
        , p [] [ text (Debug.toString rootModel.processedHealthcheckData) ]
        , case rootModel.selectedHealthcheckId of
            Just id ->
                case Dict.get "myKey" rootModel.processedHealthcheckData of
                    Just data ->
                        viewLineChart data

                    Nothing ->
                        div [] [ text "No data for key 'myKey'" ]

            Nothing ->
                div [] [ text "No healthcheck selected yet" ]
        ]


viewHealthchecks : List HealthcheckData.Healthcheck -> Html.Html Msg
viewHealthchecks healthchecks =
    div []
        (List.map
            (\healthcheck -> viewHealthcheckListItem healthcheck)
            healthchecks
        )


viewHealthcheckListItem : HealthcheckData.Healthcheck -> Html.Html Msg
viewHealthcheckListItem healthcheck =
    div []
        [ button [ onClick (HealthcheckListItemSelected healthcheck.id) ] [ text healthcheck.name ]
        ]


viewLineChart : List ( Float, Float ) -> Html.Html Msg
viewLineChart data =
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
                data
            ]
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
            case List.all HealthcheckData.isNumericField healthcheckFields of
                True ->
                    Ok (List.indexedMap Tuple.pair (List.map HealthcheckData.extractNumeric healthcheckFields))

                False ->
                    Err "Not all numerics"


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
