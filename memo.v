<header>
{.if 0@upload_flg=0}
        {.cgi content-type application/json}
{.endif}

{.select partner_id from deskpad.user where user_id='@cookie_user`ESC' and user_type='@cookie_user_type`ESC'}
{.select IF('@cookie_user_type'='Partner',@cookie_user,0@partner_id) as emp_id}

</header>

<init>
#include <include/rights.h>

var bottomTabDiv = new JDOM ([ { "div" : { "action":"replace", "attrib": { "id":"bottomtab"} } } ]);
elid("bottomtab").setAttribute("class","");

var toolbarButtonsDiv = new JDOM ([ { "div" : { "action":"replace", "attrib": { "id":"toolbar.buttons" } } } ]);
var toolbarDiv = new JDOM ([ { "div" : { "action":"replace", "attrib": { "id":"toolbar" } } } ]);

var newButton = new JDOM([
        {.if select '@new_priv'='Y'}
        {"li":{"parent":document.getElementById('toolbar.buttons'),"child":[
                {"a":{"attrib":{"id":"New"},"event":{"click":"jx.call('tpl={.tpl}&tph=memoEdit');"},"child":[
                        {"img":{"attrib":{"src":"/images/tab/new.png","title":"New","border":"0"}}}
                ]}}
        ]}},
        {.endif}
]);

elid("body").style.marginTop="0px";

var searchButton = new JDOM ([
        { "li": { "parent":document.getElementById('toolbar.buttons'), "child":[
                {"a": { "attrib":{"id":"Search"}, "event":{"click":"jx.box('SearchOnline','tpl={.tpl}&tph=SearchOnline',true, elid('body'))"}, "child":[ {"img": {"attrib":{"src":"/images/tab/search.png", "title":"Search", "border":"0"}} } ]}}
        ] } }
]);

{.if 0@srch_flg_online=1}
        {.select "user_id, user_ID, student_id, family_id, applicant_id, email, username, last_name, first_name" as field_list, "user_ID$='_data_', srch_ID$='_data_', student_ID$='_data_', family_ID$='_data_', applicant_ID$='_data_', s_email$ like '_data_%'`ESC, s_username$ like '_data_%'`ESC, s_surname$ like '_data_%'`ESC, s_firstname$ like '_data_%'`ESC" as field_values}
{.endif}

var bodyDiv = new JDOM([{"div":{"action":"replace","attrib":{"id":"body"},"child":[]}}]);

{.select count(*) as on_cnt, IFNULL(0@curpage,0) as curpage, 25 as lp, 25 as plimit from hr.memos}

var tableRows = [
        {"tr":{"child":[
                {"td":{"text":"This is the listing of Memos....","attrib":{"colspan":"6","class":"copy"}}}
        ]}},
        {"tr":{"child":[ {"td":{"attrib":{"height":"10px","colspan":"6"}}} ]}},
        {"tr":{"child":[{"td":{"attrib":{"colspan":"6","class":"bar"}}}]}},
        {"tr":{"child":[{"td":{"attrib":{"colspan":"6","class":"space"}}}]}},
        {"tr":{"child":[
                {"th":{"attrib":{}, "css":{"width":"10%", "padding-left":"5px"}, "text":"Memo ID"}},
                {"th":{"attrib":{}, "css":{"width":"15%", "padding-left":"5px"}, "text":"Date"}},
                {"th":{"attrib":{}, "css":{"width":"15%", "padding-left":"5px"}, "text":"From"}},
                {"th":{"attrib":{}, "css":{"width":"25%", "padding-left":"5px"}, "text":"To"}},
                {"th":{"attrib":{}, "css":{"width":"35%", "padding-left":"5px"}, "text":"Subject"}},
        ]}},
        {"tr":{"child":[{"td":{"attrib":{"colspan":"6","class":"space"}}}]}},
        {"tr":{"child":[{"td":{"attrib":{"colspan":"6","class":"bar"}}}]}}
];

{.while SELECT 
    m.memo_id,
    date_format(m.date,"%M %d, %Y") as sntD, 
    m.`to` as sntTo, 
    m.`from` as sntFrom, 
    m.subject, 
    m.isGrouped,
    CASE 
        WHEN m.isGrouped = 'Everyone' THEN 'Everyone'
        ELSE (
            SELECT GROUP_CONCAT(
                CONCAT(IFNULL(e.first_name,''), ' ', IFNULL(e.middle_name,''), ' ', IFNULL(e.surname,''))
                SEPARATOR '|'
            )
            FROM employee.info e 
            WHERE FIND_IN_SET(e.emp_id, REPLACE(REPLACE(m.`to`, '''', ''), ',', ','))
        )
    END as toDisplay
FROM hr.memos m 
ORDER BY m.date DESC 
LIMIT 0@curpage,0@lp }

// Convert pipe-separated names to HTML with line breaks
var toDisplayHTML = '{.toDisplay}';
if (toDisplayHTML && toDisplayHTML !== 'Everyone' && toDisplayHTML.indexOf('|') > -1) {
    toDisplayHTML = toDisplayHTML.split('|').join('<br>');
}

tableRows.push(
    {"tr":{"attrib":{"class":"row_list"}, "css":{"height":"auto","min-height":"20px"},  "child":[
            {"td":{"css":{"cursor":"pointer","padding":"5px"},"text":'{.memo_id}'}},
            {"td":{"css":{"cursor":"pointer","padding":"5px"},"text":'{.sntD}'}},
            {"td":{"css":{"cursor":"pointer","padding":"5px"},"text":'{.sntFrom}'}},
            {"td":{"css":{"cursor":"pointer","padding":"5px"},"html":toDisplayHTML}},
            {"td":{"css":{"cursor":"pointer","padding":"5px"},"text":'{.subject}'}},
    ], "event":{"click":"{.if '@update_priv'='Y'}jx.call('tpl={.tpl}&tph=memoEdit&memo_id={.memo_id}'){.else}jx.call('tpl={.tpl}&tph=sentCont&memo_id={.memo_id}'){.endif}"}}}
);

tableRows.push(
    {"tr":{"child":[{"td":{"attrib":{"colspan":"6"}, "css":{"height":"1px", "background-color":"#CCCCCC"}}}]}}
);

{.wend}

tableRows.push(
    {"tr":{"child":[{"td":{"attrib":{"colspan":"6","height":"1"}}}]}},
    {"tr":{"child":[{"td":{"attrib":{"colspan":"6","id":"pagination","height":"1"}}}]}},
    {"tr":{"child":[{"td":{"attrib":{"colspan":"6","height":"1"}}}]}}
);

var mainContent = new JDOM([{"div":{"parent":document.getElementById('body'),"attrib":{"border":"0","cellpadding":"0","cellspacing":"0","width":"100%"},"child":[
        {"table":{"attrib":{"id":"mess_dis", "cellspacing":0, "cellpadding": 0},"css":{"width":"100%"},"child": tableRows}},
        {"div":{"css":{"display":"none","width":"100%","vertical-align":"top","margin-top":"30px"},"child":[
                {"table":{"attrib":{"id":"message"}}}
        ]}}
]}}]);

Pager('{.on_cnt}', '{.curpage}', '{.lp}', '{.plimit}','tpl={.tpl}&tph=init&srch_flg_online={.srch_flg_online}&sntD={.sntD}&sntM={.sntM}','','document.getElementById(\'pagination\')');

</init>

<sentCont>
{.SELECT date_format(date,"%M %d, %Y") as sentDate, `to` as sentTo, `from` as sentFrom, subject as sentSubject, memo_id, `body`, isGrouped from hr.memos where memo_id=0@memo_id }

var messageDisplay = new JDOM([
        {"table":{"action":"replace","css":{"width":"100%"}, "attrib":{"id":"message"},"child":[
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px", "text-align":"right"}, "child":[
                                {"span":{"text":"Close", "css":{"cursor":"pointer"}, "event":{"click":"$close()"}}}
                        ]}}
                ]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"border":"0", "outline":"none", "width":"100%", "font-size":"10pt"}, "attrib":{"alt":"string"}, "text":'Date : {.sentDate}'}}
                        ]}}
                ]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"border":"0", "outline":"none", "width":"100%", "font-size":"10pt"}, "attrib":{"alt":"string", "name":"m_from"}, "text":'From : {.sentFrom}'}}
                        ]}}
                ]}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"border":"0", "outline":"none", "width":"100%", "font-size":"10pt"}, "attrib":{"alt":"string", "name":"m_subject"}, "text":'To : {.if "@isGrouped"="Everyone"}Everyone{.else}{.sentTo}{.endif}'}}
                        ]}}
                ]}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"border":"0", "outline":"none", "width":"100%", "font-size":"10pt"}, "attrib":{"alt":"string", "name":"m_subject"}, "text":'Subject : {.sentSubject}'}}
                        ]}}
                ]}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"child":[
                        {"td":{"child":[
                                {"div":{"css":{"margin-left":"5px", "padding":"20px"}, "html":"{.body}"}}
                        ]}}
                ]}},
                {"tr":{"css":{"height":"50px"}}}
        ]}}
]);

elid('message').parentNode.style.display='';
elid('message').parentNode.previousSibling.style.display='none';

$close = function(){
    elid('message').parentNode.style.display='none';
    elid('message').parentNode.previousSibling.style.display='';
};

</sentCont>

<memoEdit>
{.SELECT date as sentDate, `to` as sentTo, `from` as sentFrom, subject as sentSubject, memo_id, `body`, isGrouped from hr.memos where memo_id=0@memo_id }

var memoEditForm = new JDOM([
        {"table":{"action":"replace","css":{"width":"100%"}, "attrib":{"id":"message"},"child":[
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"color":"red", "margin-right":"5px"}, "text":"*"}},
                                {"input":{"css":{"border":"1px solid #ccc", "outline":"none", "width":"110px", "font-size":"10pt"}, "attrib":{"alt":"string", "name":"m_date", "value":"{.sentDate}", "alt":"date", "placeholder":"Date", "required":"required"}}}
                        ]}}
                ]}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"color":"red", "margin-right":"5px"}, "text":"*"}},
                                {"input":{"css":{"border":"1px solid #ccc", "outline":"none", "width":"calc(100% - 20px)", "font-size":"10pt"}, "attrib":{"alt":"string", "name":"m_from", "value":'{.sentFrom}', "placeholder":"From", "required":"required"}}}
                        ]}}
                ]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"input":{"attrib":{"type":"checkbox", "id":"everyone_checkbox"}, "event":{"change":"$toggleEveryone()"}}},
                                {"label":{"attrib":{"for":"everyone_checkbox"}, "css":{"margin-left":"5px", "font-size":"10pt"}, "text":"Send to Everyone"}}
                        ]}}
                ]}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"auto", "min-height":"25px", "position":"relative"}, "child":[
                                {"span":{"css":{"color":"red", "margin-right":"5px"}, "text":"*"}},
                                {"span":{"css":{"font-size":"10pt"}, "text":"To:"}},
                                {"div":{"attrib":{"id":"selected_employees"}, "css":{"margin-bottom":"5px", "min-height":"20px", "margin-top":"5px"}}},
                                {"input":{"css":{"border":"1px solid #ccc", "outline":"none", "width":"calc(100% - 20px)", "font-size":"10pt"}, "attrib":{"id":"m_to", "placeholder":"Type employee name...", "autocomplete":"off"}, "event":{"input":"$suggest.get(this.value)"}}},
                                {"div":{"attrib":{"id":"to_suggestions"}, "css":{"display":"none", "position":"absolute", "background":"white", "border":"1px solid #ccc", "max-height":"200px", "overflow-y":"auto", "z-index":"1000", "width":"calc(100% - 20px)", "margin-left":"15px"}}}
                        ]}}
                ]}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"child":[
                        {"td":{"css":{"width":"100%", "height":"25px"}, "child":[
                                {"span":{"css":{"color":"red", "margin-right":"5px"}, "text":"*"}},
                                {"input":{"css":{"border":"1px solid #ccc", "outline":"none", "width":"calc(100% - 20px)", "font-size":"10pt"}, "attrib":{"alt":"string", "name":"m_subject", "value":'{.sentSubject}', "placeholder":"Subject", "required":"required"}}}
                        ]}}
                ]}},
                {"tr":{"child":[
                        {"td":{"child":[
                                {"span":{"css":{"color":"red", "margin-right":"5px"}, "text":"*"}},
                                {"span":{"css":{"font-size":"10pt"}, "text":"Message:"}},
                                {"textarea":{"attrib":{"id":"edit_m", "value":'{.body}', "required":"required"}, "css":{"width":"calc(100% - 20px)", "margin-top":"5px", "margin-left":"15px", "border":"1px solid #ccc", "min-height":"100px"}}}
                        ]}}
                ]}},
                {"tr":{"css":{"height":"5px"}}},
                {"tr":{"child":[{"td":{"css":{"height":"1px", "background-color":"#ccc"}}}]}},
                {"tr":{"css":{"height":"5px"}}},
                {"tr":{"child":[
                        {"td":{"child":[
                                {"span":{"css":{"font-size":"9pt", "color":"#666", "margin-right":"10px"}, "text":"* Required fields"}},
                                {"input":{"attrib":{"type":"button", "value":"Save"}, "css":{"border":0, "outline":"none", "background-color":"green", "color":"white", "font-size":"10pt", "width":"75px", "cursor":"pointer"}, "event":{"click":"$action.create()"}}}
                        ]}}
                ]}}
        ]}}
]);

$toggleEveryone = function() {
        var checkbox = document.getElementById('everyone_checkbox');
        var toInput = document.getElementById('m_to');
        var selectedEmployees = document.getElementById('selected_employees');
        var suggestions = document.getElementById('to_suggestions');
        
        if (checkbox.checked) {
                toInput.disabled = true;
                toInput.style.backgroundColor = '#f0f0f0';
                toInput.style.color = '#999';
                toInput.value = '';
                toInput.removeAttribute('required');
                selectedEmployees.innerHTML = '';
                suggestions.style.display = 'none';
                if (typeof $suggest !== 'undefined') {
                    $suggest.selectedEmployees = [];
                }
        } else {
                toInput.disabled = false;
                toInput.style.backgroundColor = '';
                toInput.style.color = '';
                toInput.setAttribute('required', 'required');
        }
};

$suggest = {
        "lastQuery": "",
        "selectedEmployees": [],
        "get":function(value){
                var q = value.trim();
                if(q.length < 2){
                        document.getElementById('to_suggestions').style.display = 'none';
                        return;
                }
                
                if (q === this.lastQuery) {
                        return;
                }
                this.lastQuery = q;
                
                jx.post('tpl={.tpl}&tph=empSuggest&q=' + encodeURIComponent(q));
        },
        "select":function(name, id){
                var exists = this.selectedEmployees.find(function(emp) { return emp.id === id; });
                if (exists) {
                        return;
                }
                
                this.selectedEmployees.push({name: name, id: id});
                
                document.getElementById('m_to').value = '';
                document.getElementById('to_suggestions').style.display = 'none';
                
                this.updateDisplay();
        },
        "remove":function(id){
                var self = this;
                this.selectedEmployees = this.selectedEmployees.filter(function(emp) { return emp.id !== id; });
                this.updateDisplay();
        },
        "updateDisplay":function(){
                var container = document.getElementById('selected_employees');
                var html = '';
                
                for(var i = 0; i < this.selectedEmployees.length; i++){
                        var emp = this.selectedEmployees[i];
                        html += '<span style="display:inline-block; background:#e0e0e0; padding:2px 8px; margin:2px; border-radius:3px; font-size:10pt;">' + 
                                emp.name + 
                                ' <span style="cursor:pointer; color:red; font-weight:bold;" onclick="$suggest.remove(\'' + emp.id + '\')">×</span>' +
                                '</span>';
                }
                
                container.innerHTML = html;
        },
        "getSelectedIds":function(){
                return this.selectedEmployees.map(function(emp) { return emp.id; });
        },
        "parseExistingEmployees":function(toField){
                if(!toField || toField.trim() === '') return;
                
                var matches = toField.match(/'([^']+)'/g);
                if(matches){
                        this.selectedEmployees = [];
                        for(var i = 0; i < matches.length; i++){
                                var empId = matches[i].replace(/'/g, '');
                                this.fetchEmployeeName(empId);
                        }
                }
        },
        "fetchEmployeeName":function(empId){
                jx.post('tpl={.tpl}&tph=getEmpName&emp_id=' + encodeURIComponent(empId));
        },
        "addExistingEmployee":function(name, id){
                this.selectedEmployees.push({name: name, id: id});
                this.updateDisplay();
        }
};

$action = {
        "init":function(){
                if (typeof CKEDITOR !== 'undefined') {
                    CKEDITOR.replace('edit_m');
                    CKEDITOR.config.enterMode = CKEDITOR.ENTER_BR;
                    CKEDITOR.config.uploadUrl='/app/ckeditor.cf';
                }
                
                var isGrouped = '{.isGrouped}';
                if(isGrouped === 'Everyone'){
                    document.getElementById('everyone_checkbox').checked = true;
                    $toggleEveryone();
                } else {
                    var existingTo = '{.sentTo}';
                    if(existingTo && existingTo.trim() !== ''){
                        $suggest.parseExistingEmployees(existingTo);
                    }
                }
        },
        "create":function(){
                // Validate required fields
                var dateField = document.getElementsByName('m_date')[0];
                var fromField = document.getElementsByName('m_from')[0];
                var subjectField = document.getElementsByName('m_subject')[0];
                var everyoneChecked = document.getElementById('everyone_checkbox').checked;
                
                // Check if required fields are filled
                if (!dateField.value.trim()) {
                    alert('Date is required!');
                    dateField.focus();
                    return;
                }
                
                if (!fromField.value.trim()) {
                    alert('From field is required!');
                    fromField.focus();
                    return;
                }
                
                if (!subjectField.value.trim()) {
                    alert('Subject is required!');
                    subjectField.focus();
                    return;
                }
                
                // Check if "To" field is properly filled
                if (!everyoneChecked && $suggest.selectedEmployees.length === 0) {
                    alert('Please select at least one recipient or check "Send to Everyone"!');
                    document.getElementById('m_to').focus();
                    return;
                }
                
                // Get message content
                var TextGrab = '';
                if (typeof CKEDITOR !== 'undefined' && CKEDITOR.instances['edit_m']) {
                    TextGrab = CKEDITOR.instances['edit_m'].getData();
                    TextGrab = TextGrab.replace(/\&nbsp;/g, ' ').replace(/class="marker"/g, 'style="background-color: yellow;"').replace(/[\n\r]/g, "");
                } else {
                    TextGrab = document.getElementById('edit_m').value;
                }
                
                if (!TextGrab.trim()) {
                    alert('Message content is required!');
                    if (typeof CKEDITOR !== 'undefined' && CKEDITOR.instances['edit_m']) {
                        CKEDITOR.instances['edit_m'].focus();
                    } else {
                        document.getElementById('edit_m').focus();
                    }
                    return;
                }
                
                var toField = '';
                var isGrouped = 'None';

                if (everyoneChecked) {
                    toField = '';
                    isGrouped = 'Everyone';
                } else {
                    var selectedIds = $suggest.getSelectedIds();
                    toField = selectedIds.length > 0 ? "'" + selectedIds.join("','") + "'" : '';
                    isGrouped = 'None';
                }

                jx.post('tpl={.tpl}&tph=save&memo_id={.memo_id}' +
                       '&m_date=' + encodeURIComponent(dateField.value) + 
                       '&m_from=' + encodeURIComponent(fromField.value) + 
                       '&m_to=' + encodeURIComponent(toField) + 
                       '&m_subject=' + encodeURIComponent(subjectField.value) + 
                       '&m_message=' + encodeURIComponent(TextGrab) +
                       '&isGrouped=' + encodeURIComponent(isGrouped));
        }
};

$action.init();

elid('message').parentNode.style.display='';
elid('message').parentNode.previousSibling.style.display='none';

</memoEdit>

<save>
{.if 0@memo_id=0}
    {.insert into hr.memos (`date`,`to`,`from`,`subject`,`body`,`isGrouped`) values ('@m_date`DATE','@m_to`ESC','@m_from`ESC','@m_subject`ESC','@m_message`ESC','@isGrouped`ESC')}
{.else}
    {.update hr.memos set `date`='@m_date`DATE',`to`='@m_to`ESC',`from`='@m_from`ESC',`subject`='@m_subject`ESC',`body`='@m_message`ESC',`isGrouped`='@isGrouped`ESC' where memo_id=0@memo_id}
{.endif}

elid('message').parentNode.style.display='none';
elid('message').parentNode.previousSibling.style.display='';

jx.call('tpl={.tpl}&tph=init');

</save>

<empSuggest>
{.noheader}
{.nodebug}
var html = '';
{.while select emp_id, first_name, middle_name, surname from employee.info 
where (first_name like '%@q`ESC%' or surname like '%@q`ESC%' or emp_id like '%@q`ESC%')
limit 10}html += '<div style="padding:4px 8px; cursor:pointer;" onmouseover="this.style.background=\'#f0f0f0\';" onmouseout="this.style.background=\'#fff\';" onclick="$suggest.select(\'{.first_name} {.middle_name} {.surname}\', \'{.emp_id}\');">{.first_name} {.middle_name} {.surname}</div>';
{.wend}
var suggestionBox = document.getElementById('to_suggestions');
if (suggestionBox) {
    suggestionBox.innerHTML = html;
    suggestionBox.style.display = html ? 'block' : 'none';
}
</empSuggest>

<getEmpName>
{.noheader}
{.nodebug}
{.select first_name, middle_name, surname from employee.info where emp_id='@emp_id`ESC'}
if (typeof $suggest !== 'undefined') {
    $suggest.addExistingEmployee('{.first_name} {.middle_name} {.surname}', '@emp_id');
}
</getEmpName>