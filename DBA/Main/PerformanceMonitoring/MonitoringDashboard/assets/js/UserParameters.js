$(function() {
    $('#datetimepickerStart1').datetimepicker();
    $('#datetimepickerEnd1').datetimepicker();
    $('#datetimepickerStart2').datetimepicker();
    $('#datetimepickerEnd2').datetimepicker();
   
    $('#environments1').change(function() {
            var environments = $('#environmentsAsJson').val();
            var selectedEnvironment = $("#environments1 option:selected").text();
            var environmentsJson = jQuery.parseJSON(environments);
            var databaseCheckboxesHtml = '';
            var index;
            for (index = 0; index < environmentsJson.EnvironmentsOfInterest.length; index++) {
                if (environmentsJson.EnvironmentsOfInterest[index].EnvironmentName == selectedEnvironment) {
                    var databases = environmentsJson.EnvironmentsOfInterest[index].Databases;
                    var dbindex = 0;
                    for (dbindex = 0; dbindex < databases.length; dbindex++) {
                        var db = databases[dbindex];
                        databaseCheckboxesHtml = databaseCheckboxesHtml + '<div class="databaseOfInterestContainer"><input type="checkbox" value="' + db + '"><span>' + db + '</span></div>';
                    }
                }
            }
            $('#criteria1DatabasesContainer').html(databaseCheckboxesHtml);
        }
    );
    $('#environments2').change(function() {
            var environments = $('#environmentsAsJson').val();
            var selectedEnvironment = $("#environments2 option:selected").text();
            var databaseCheckboxesHtml = '';
            if (selectedEnvironment == 'Not Required') {
                databaseCheckboxesHtml = "<div class='databaseOfInterestContainer'><span>No databases to specify.</span></div>";
                $('#datetimepickerStart2').val('');
                $('#datetimepickerEnd2').val('');
            } else {
                var environmentsJson = jQuery.parseJSON(environments);
                var index;
                for (index = 0; index < environmentsJson.EnvironmentsOfInterest.length; index++) {
                    if (environmentsJson.EnvironmentsOfInterest[index].EnvironmentName == selectedEnvironment) {
                        var databases = environmentsJson.EnvironmentsOfInterest[index].Databases;
                        var dbindex = 0;
                        for (dbindex = 0; dbindex < databases.length; dbindex++) {
                            var db = databases[dbindex];
                            databaseCheckboxesHtml = databaseCheckboxesHtml + '<div class="databaseOfInterestContainer"><input type="checkbox" value="' + db + '"><span>' + db + '</span></div>';
                        }
                    }
                }
            }
            $('#criteria2DatabasesContainer').html(databaseCheckboxesHtml);
        }
    );

});


function ValidateInputs() {
    var validationString = '';
    var validationString2 = '';
    var validationString3 = '';
    var enviroSet1 = $("#environments1 option:selected").val();
    var databaseSet1 = $('#criteria1DatabasesContainer div input:checked').val();
    var databaseSet2 = $('#criteria2DatabasesContainer div input:checked').val();    
    var date1S1 = $('#datetimepickerStart1').val();
    var date2S1 = $('#datetimepickerEnd1').val();
    var enviroSet2 = $('#environments2 option:selected').val();
    var date1S2 = $('#datetimepickerStart2').val();
    var date2S2 = $('#datetimepickerEnd2').val();

    var date1Set1 = date1S1;
    var format = /(\d{4})\/(\d{2})\/(\d{2}) (\d{2}):(\d{2})/;
    var dateArray = format.exec(date1Set1);
    try {
        var newDate = new Date(
            (+dateArray[1]),
            (+dateArray[2]) - 1,
            (+dateArray[3]),
            (+dateArray[4]),
            (+dateArray[5])
        );
    } catch (exception) {
    }
    //
    var date2Set1 = date2S1;
    var dateArray2 = format.exec(date2Set1);
    try {
        var newDate2 = new Date(
            (+dateArray2[1]),
            (+dateArray2[2]) - 1,
            (+dateArray2[3]),
            (+dateArray2[4]),
            (+dateArray2[5])
        );
    } catch (e) {
    }
    //
    var date1Set2 = date1S2;
    var dateArray3 = format.exec(date1Set2);
    try {
        var newDate3 = new Date(
            (+dateArray3[1]),
            (+dateArray3[2]) - 1,
            (+dateArray3[3]),
            (+dateArray3[4]),
            (+dateArray3[5])
        );
    } catch (e) {
    }
    //
    var date2Set2 = date2S2;
    var dateArray4 = format.exec(date2Set2);
    try {
        var newDate4 = new Date(
            (+dateArray4[1]),
            (+dateArray4[2]) - 1,
            (+dateArray4[3]),
            (+dateArray4[4]),
            (+dateArray4[5])
        );
    } catch (e) {
    }

    //Check to see what data has been left out
    //Environment for set 1 is empty
    if (enviroSet1 === 'none')
    (validationString = validationString + 'Select an environment for set 1.');

    //First date for set 1 is empty
    if (date1S1 === '')
    (validationString = validationString + '<br />Select a valid first date for set 1.');

    //Second date for set 1 is empty
    if (date2S1 === '')
    (validationString = validationString + '<br />Select a valid second date for set 1.');
    //Datebase for set 1 is not selected
    if (databaseSet1 === undefined & enviroSet1 !== 'none') {
        (validationString = validationString + '<br />Select a database for set 1.');
    }
    //Environment for set 2 isn't selected (and data for set 1 is filled in)
    if (enviroSet2 === "none" & date1S2 !== "" & date2S2 !== "" & enviroSet1 !== "none" & date1S1 !== "" & date2S1 !== "") {
        (validationString2 = 'Select an environment for set 2.');
    }//First data for set 2 isn't selected (and data for set 1 is filled in)
    if (enviroSet2 !== "none" & date1S2 === "" & date2S2 !== "" & enviroSet1 !== "none" & date1S1 !== "" & date2S1 !== "") {
        (validationString2 = validationString2 + '<br />Select a valid first date for set 2.');
    }//Second date for set 2 isn't selected (and data for set 1 is filled in)
    if (enviroSet2 !== "none" & date1S2 !== "" & enviroSet1 !== "none" & date2S2 === "" & date1S1 !== "" & date2S1 !== "") {
        (validationString2 = validationString2 + '<br />Select a valid second date for set 2');
    }//Database for set 2 is not selected
    if (databaseSet2 === undefined & enviroSet2 !== 'none') {
        (validationString2 = validationString2 + '<br />Select a database for set 2.');
    }

    //The first date is bigger than the second date for set 1 or not datetime
    if (newDate > newDate2) {
        (validationString3 = 'The first date is bigger than the second for set 1.');
    }

    //The first date is bigger than the second date for set 2 or not datetime
    if (newDate < newDate2 && newDate3 > newDate4) {
        (validationString3 = validationString3 + '<br />The first date is bigger than the second for set 2.');
    }

    //Checks if any of the dates are in the future or not datetime
    if (newDate > Date.now() || newDate2 > Date.now() || newDate3 > Date.now() || newDate4 > Date.now()) {
        (validationString3 = validationString3 + '<br />A date is in the furture for a set.');
    }
        $('#dialog-validate-Input').dialog({
            autoOpen: false,
            modal: true,           
        });
            //Open dialog
            if (validationString !== '' || validationString2 !== '' || validationString3 !== '') {
                $('#dialog-validate-Input').html(validationString + '<br />' + validationString2 + '<br />' + validationString3);
                $('#dialog-validate-Input').dialog('open');
                return false;
            }
            else
                return true;            
}


function UserPreferences() {
    var databases1 = [];
    $('#criteria1DatabasesContainer div input:checked').each(
        function () {
            databases1.push($(this).val());
        }
    );


    this.Criteria1 = {
        EnvironmentName: $("#environments1 option:selected").val(),
        DatabasesOfInterest: databases1,
        Start: $('#datetimepickerStart1').val(),
        End: $('#datetimepickerEnd1').val()

    };


    var selectedEnvironment = $("#environments2 option:selected").text();
    if (selectedEnvironment == 'Not Required') {
        this.Criteria2 = null;
    } else {

        var databases2 = [];
        $('#criteria2DatabasesContainer div input:checked').each(
            function () {
                databases2.push($(this).val());
            }
        );


        this.Criteria2 = {
            EnvironmentName: $("#environments2 option:selected").val(),
            DatabasesOfInterest: databases2,
            Start: $('#datetimepickerStart2').val(),
            End: $('#datetimepickerEnd2').val()
        };
    }

}