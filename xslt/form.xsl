<?xml version="1.0" ?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:f="http://dh.tamu.edu/ns/fabulator/1.0#"
  exclude-result-prefixes="f"
  version="1.0"
>
  <xsl:output
    method="html"
    indent="yes"
  />

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="//f:form">
    <xsl:choose>
      <xsl:when test="''">
        <xsl:call-template name="form-content" />
      </xsl:when>
      <xsl:otherwise>
        <form>
          <xsl:attribute name="type">application/x-multipart</xsl:attribute>
          <xsl:attribute name="method">POST</xsl:attribute>
          <xsl:attribute name="class">fabulator-form</xsl:attribute>
          <xsl:call-template name="form-content" />
        </form>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="form-content">
    <xsl:param name="form_level">1</xsl:param>
    <table class="form-content" border="0" cellspacing="0" cellpadding="0">
      <xsl:apply-templates select="f:text|f:asset|f:password|f:selection|f:form|f:group">
        <xsl:with-param name="form_level"><xsl:value-of select="$form_level" /></xsl:with-param>
      </xsl:apply-templates>
      <xsl:if test="f:submission|f:reset">
        <tr><td colspan="2" align="center">
          <xsl:apply-templates select="f:submission|f:reset" />
        </td></tr>
      </xsl:if>
    </table>
    <xsl:apply-templates select="f:value" />
  </xsl:template>

  <xsl:template match="f:form/f:form | f:option/f:form">
    <xsl:param name="form_level" />
    <xsl:choose>
      <xsl:when test="frame:caption">
        <tr><td colspan="2">
        <fieldset>
          <legend><xsl:apply-templates select="caption" /></legend>
          <xsl:call-template name="form-content">
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level + 1"/></xsl:with-param>
          </xsl:call-template>
        </fieldset>
        </td></tr>
      </xsl:when>
      <xsl:otherwise>
        <tr><td colspan="2">
        <xsl:call-template name="form-content">
          <xsl:with-param name="form_level"><xsl:value-of select="$form_level + 1" /></xsl:with-param>
        </xsl:call-template>
        </td></tr>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:text">
    <tr><td class="form-caption" valign="top">
      <xsl:apply-templates select="f:caption" />
    </td><td class="form-element" valign="top">
      <xsl:choose>
        <xsl:when test="@f:rows > 1 or @rows > 1">
          <textarea>
            <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
            <xsl:attribute name="rows"><xsl:choose>
              <xsl:when test="@f:rows"><xsl:value-of select="@f:rows"/></xsl:when>
              <xsl:when test="@rows"><xsl:value-of select="@rows"/></xsl:when>
            </xsl:choose></xsl:attribute>
            <xsl:attribute name="cols">
              <xsl:choose>
                <xsl:when test="@f:cols > 132 or @cols > 132">132</xsl:when>
                <xsl:when test="@f:cols"><xsl:value-of select="@f:cols" /></xsl:when>
                <xsl:when test="@cols"><xsl:value-of select="@cols" /></xsl:when>
                <xsl:otherwise>60</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates select="f:default" />
            <xsl:text> </xsl:text>
          </textarea>
        </xsl:when>
        <xsl:otherwise>
          <input>
            <xsl:attribute name="type">text</xsl:attribute>
            <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
            <xsl:attribute name="size">
              <xsl:choose>
                <xsl:when test="@f:cols > 40 or @cols > 40">40</xsl:when>
                <xsl:when test="@f:cols"><xsl:value-of select="@f:cols" /></xsl:when>
                <xsl:when test="@cols"><xsl:value-of select="@cols" /></xsl:when>
                <xsl:otherwise>12</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <xsl:attribute name="value"><xsl:apply-templates select="f:default" /></xsl:attribute>
          </input>
        </xsl:otherwise>
      </xsl:choose>
    </td></tr>
  </xsl:template>

  <xsl:template match="f:password">
    <tr><td class="form-caption" valign="top">
      <xsl:apply-templates select="f:caption" />
    </td><td class="form-element" valign="top">
      <input>
        <xsl:attribute name="type">password</xsl:attribute>
        <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
      </input>
    </td></tr>
  </xsl:template>

  <xsl:template match="f:asset">
    <div class="form-element">
      <xsl:apply-templates select="f:caption" />
      <span class="form-fluid-asset"></span>
      <input>
        <xsl:attribute name="class">form-asset</xsl:attribute>
        <xsl:attribute name="type">file</xsl:attribute>
        <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
        <xsl:if test="@f:accept">
          <xsl:attribute name="accept"><xsl:value-of select="@f:accept" /></xsl:attribute>
        </xsl:if>
      </input>
    </div>
  </xsl:template>

  <xsl:template match="f:selection">
  </xsl:template>

  <xsl:template match="f:group">
     <xsl:param name="form_level" />
     <xsl:apply-templates select="f:caption" />
     <xsl:call-template name="form-content">
       <xsl:with-param name="form_level"><xsl:value-of select="$form_level" /></xsl:with-param>
     </xsl:call-template>
  </xsl:template>

  <xsl:template match="f:submission">
    <xsl:choose>
      <xsl:when test="f:caption or f:default">
        <button>
          <xsl:attribute name="type">submit</xsl:attribute>
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
          <xsl:attribute name="value">
            <xsl:choose>
              <xsl:when test="f:default">
                <xsl:value-of select="f:default" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="f:caption" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates select="f:caption" />
        </button>
      </xsl:when>
      <xsl:otherwise>
        <input>
          <xsl:attribute name="type">submit</xsl:attribute>
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
          <xsl:attribute name="value">
            <xsl:choose>
              <xsl:when test="f:default">
                <xsl:value-of select="f:default" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="f:caption" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:reset">
    <xsl:choose>
      <xsl:when test="f:caption">
        <button>
          <xsl:attribute name="type">reset</xsl:attribute>
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
          <xsl:apply-templates select="f:caption" />
        </button>
      </xsl:when>
      <xsl:otherwise>
        <input>
          <xsl:attribute name="type">reset</xsl:attribute>
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
          <xsl:attribute name="value"><xsl:value-of select="f:caption" /></xsl:attribute>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:value">
    <input>
      <xsl:attribute name="type">hidden</xsl:attribute>
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
      <xsl:attribute name="value"><xsl:apply-templates select="default" /></xsl:attribute>
    </input>
  </xsl:template>

  <xsl:template match="f:caption">
    <span class="caption"><xsl:apply-templates /></span>
  </xsl:template>

  <xsl:template match="f:default">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="*" mode="id">
    <xsl:for-each select="ancestor::*[@id != '']">
      <xsl:value-of select="@id" />
      <xsl:if test="position() != last()">
        <xsl:text>.</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="@id">
      <xsl:if test="ancestor::*[@id != '']">
        <xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:value-of select="@id" />
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
