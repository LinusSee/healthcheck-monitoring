module BusinessLogic.Healthcheck exposing (extractValuesForRoots)

import Models.HealthcheckData exposing (..)
import Result.Extra as ResultExtra


extractValuesForRoots : HealthcheckChartConfig -> List HealthcheckRoot -> Result String (List Float)
extractValuesForRoots config roots =
    let
        ( values, errors ) =
            List.map (extractValuesForRoot config) roots
                |> ResultExtra.partition
                |> Tuple.mapFirst (List.foldr (++) [])
    in
    case List.isEmpty errors of
        True ->
            Ok values

        False ->
            Err ("Errors extracting values from roots:" ++ String.join "\n->" errors)


extractValuesForRoot : HealthcheckChartConfig -> HealthcheckRoot -> Result String (List Float)
extractValuesForRoot config root =
    let
        ( values, errors ) =
            List.filter (\node -> node.name == config.healthcheckName) root.checks
                |> List.map (extractValueForNode config)
                |> ResultExtra.partition
    in
    case List.isEmpty errors of
        True ->
            Ok values

        False ->
            Err ("Errors extracting values from root:" ++ String.join "\n->" errors)


extractValueForNode : HealthcheckChartConfig -> HealthcheckNode -> Result String Float
extractValueForNode config node =
    case node.name == config.healthcheckName of
        True ->
            let
                result =
                    extractFieldValue config node.data
            in
            case result of
                Ok _ ->
                    result

                Err error ->
                    Err ("Error extracting field for healthcheck '" ++ node.name ++ "': " ++ error)

        False ->
            Err
                ("Incorrect healthcheck node. Nodename '"
                    ++ node.name
                    ++ "' does not match name in config '"
                    ++ config.healthcheckName
                    ++ "'"
                )


extractFieldValue : HealthcheckChartConfig -> List HealthcheckField -> Result String Float
extractFieldValue config fields =
    let
        maybeResult =
            List.filter (\field -> field.fieldname == config.fieldname) fields
                |> List.map (\field -> extractNumericValue field.value)
                |> List.head
    in
    case maybeResult of
        Just result ->
            case result of
                Ok _ ->
                    result

                Err error ->
                    Err ("Error extracting field for name '" ++ config.fieldname ++ "': " ++ error)

        Nothing ->
            Err ("Could not extract a value from healthcheckFields for fieldname '" ++ config.fieldname ++ "''")


extractNumericValue : HealthcheckFieldValue -> Result String Float
extractNumericValue field =
    case field of
        NumericField val ->
            Ok (toFloat val)

        _ ->
            Err "Not a numeric field. Could not extract a numeric value."
