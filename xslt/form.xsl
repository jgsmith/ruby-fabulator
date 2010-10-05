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
    <xsl:apply-templates select="f:text|f:asset|f:password|f:selection|f:form|f:group">
      <xsl:with-param name="form_level"><xsl:value-of select="$form_level" /></xsl:with-param>
    </xsl:apply-templates>
    <xsl:apply-templates select="f:value" />
    <xsl:if test="f:submission|f:reset">
      <span class="buttons">
        <xsl:apply-templates select="f:submission|f:reset" />
      </span>
    </xsl:if>
  </xsl:template>

  <xsl:template match="f:form/f:form | f:option/f:form">
    <xsl:param name="form_level" />
    <xsl:choose>
      <xsl:when test="frame:caption">
        <fieldset>
          <legend><xsl:apply-templates select="caption" /></legend>
          <xsl:call-template name="form-content">
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level + 1"/></xsl:with-param>
          </xsl:call-template>
        </fieldset>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="form-content">
          <xsl:with-param name="form_level"><xsl:value-of select="$form_level + 1" /></xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:text">
    <xsl:choose>
      <xsl:when test="@f:rows > 1">
        <textarea>
          <xsl:attribute name="rows"><xsl:value-of select="@f:rows"/></xsl:attribute>
          <xsl:attribute name="cols">
            <xsl:choose>
              <xsl:when test="@f:cols > 132">132</xsl:when>
              <xsl:when test="@f:cols"><xsl:value-of select="@f:cols" /></xsl:when>
              <xsl:otherwise>60</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:variable name="content"><xsl:apply-templates select="f:default" /></xsl:variable>
          <xsl:choose>
            <xsl:when test="$content"><xsl:value-of select="$content" /></xsl:when>
            <xsl:otherwise> </xsl:otherwise>
          </xsl:choose>
        </textarea>
      </xsl:when>
      <xsl:otherwise>
        <input>
          <xsl:attribute name="type">text</xsl:attribute>
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
          <xsl:attribute name="size">
            <xsl:choose>
              <xsl:when test="@f:cols"> 40">40</xsl:when>
              <xsl:when test="@f:cols"><xsl:value-of select="@f:cols" /></xsl:when>
              <xsl:otherwise>12</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="f:password">
    <input>
      <xsl:attribute name="type">password</xsl:attribute>
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
    </input>
  </xsl:template>

  <xsl:template match="f:asset">
    <span class="form-fluid-asset"></span>
    <input>
      <xsl:attribute name="class">form-asset</xsl:attribute>
      <xsl:attribute name="type">file</xsl:attribute>
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id" /></xsl:attribute>
      <xsl:if test="@f:accept">
        <xsl:attribute name="accept"><xsl:value-of select="@f:accept" /></xsl:attribute>
      </xsl:if>
    </input>
  </xsl:template>

  <xsl:template match="f:selection">
  </xsl:template>

  <xsl:template match="f:group">
     <xsl:param name="form_level" />
     <xsl:apply-templates select="caption" />
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
          <xsl:apply-templates select="caption" />
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
