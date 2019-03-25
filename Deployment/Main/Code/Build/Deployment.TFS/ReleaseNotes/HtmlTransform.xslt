<xsl:stylesheet version="1.0"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >

  <xsl:output method="html" indent="yes"/>


  <!-- Default template -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="ReleaseNotes" >
    <html>
      <head>
        <title>Release Notes</title>
        <style type="text/css">
          ul
          {
            list-style:none;
          }
          ul.horizontal
          {
            margin: 2px;
            list-style-type:none;
            border-top: 1px solid lightblue; border-bottom: 1px solid lightblue; border-left: 4px solid lightblue;
          }
          ul.horizontal li
          {
            display:inline;
          }
          ul.horizontal li
          {
            text-decoration:none;
            padding-left: 4px;
            padding-right: 1em;
          }
        </style>
      </head>    
      <body>
        <h1>
          Release Notes
        </h1>
        <h2>
          <xsl:value-of select="concat('Start Label: ', @StartLabel)"/>
        </h2>
        <h2>
          <xsl:value-of select="concat('End Label: ', @EndLabel)"/>
        </h2>
        <h2>Changesets</h2>
        <ul id="Changesets" class="ChangesetList">
            <xsl:apply-templates select="Changesets/Changeset"/> 
        </ul>    
        <h2>Work Items</h2>
        <ul id="WorkItems" class="WorkItemList">
          <xsl:apply-templates select="WorkItems/WorkItem"/>
        </ul>     
      </body>
    </html>
  </xsl:template>

  
  <xsl:template match="Changesets/Changeset">
      <li>
        <ul class="horizontal">
          <li>
            <xsl:value-of select="ChangesetId"/>
          </li>
          <li>
            <xsl:value-of select="Date"/>
          </li>
          <li>
            <xsl:value-of select="Committer"/>
          </li>
          <li>
            <xsl:value-of select="Comment"/>
          </li>
        </ul>
      
    <xsl:if test="Changesets/Changeset">
      <ul>

        <xsl:apply-templates select="Changesets/Changeset"/>
      </ul>
    </xsl:if>
      </li>
  </xsl:template>

  <xsl:template match="WorkItems/WorkItem">
    <li>
      <ul class="horizontal">
        <li>
          <xsl:value-of select="WorkItemId"/>
        </li>
        <li>
          <xsl:value-of select="State"/>
        </li>
        <li>
          <xsl:value-of select="Title"/>
        </li>
      </ul>
    </li>
  </xsl:template>
  
</xsl:stylesheet>
