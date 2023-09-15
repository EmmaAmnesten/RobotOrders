*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get order files
    Handel all orders    ${orders}
    Create Zip file


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Approve wabpage popup

Approve wabpage popup
    Click Button    css:.btn-dark

Get order files
    ${orders}=    Get orders
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${orders}

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Handel all orders
    [Arguments]    ${Orders}
    FOR    ${order}    IN    @{orders}
        Fill in the from    ${order}
        ${ordernumber}=    Wait Until Keyword Succeeds    1 min    1 sec    Subit form with retry
        Save receipt and screenshot    ${ordernumber}
        Wait Until Keyword Succeeds    1 min    1 sec    New order with retry
    END

Fill in the from
    [Arguments]    ${order}
    Select From List By Index    head    ${order}[Head]
    ${strBodyId}=    Catenate    id-body-${order}[Body]
    Click Element    ${strBodyId}
    Input Text    css:input.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]

Subit form with retry
    Click Button    order
    Wait Until Element Is Visible    order-another    10
    ${ordernumber}=    Get Text    css:p.badge-success
    RETURN    ${ordernumber}

New order with retry
    Click Button    order-another
    Wait Until Element Is Visible    order    10
    Approve wabpage popup

Save receipt and screenshot
    [Arguments]    ${ordernumber}

    ${receipt}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}/receipt${/}receipt${ordernumber}.pdf
    ${imageRobot}=    Screenshot    robot-preview-image    ${OUTPUT_DIR}/robot${/}robot${ordernumber}.PNG

    ${files}=    Create List
    ...    ${OUTPUT_DIR}/receipt${/}receipt${ordernumber}.pdf
    ...    ${OUTPUT_DIR}/robot${/}robot${ordernumber}.PNG
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}/receipt${/}receipt${ordernumber}.pdf

Create Zip file
    ${zipFileName}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}/receipt    ${zipFileName}
