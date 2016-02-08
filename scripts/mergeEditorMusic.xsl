<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    exclude-result-prefixes="xs xd"
    version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Sep 25, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p><xd:b>Author:</xd:b> Kristin Herold</xd:p>
            <xd:p>
                This stylesheet merges a complete encoding of the music
                of one specified movement (param: $movID) entered in Finale
                or similar and converted to MEI into an Edirom Online MEI
                file with measure positions. 
            </xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:output indent="yes" encoding="UTF-8" method="xml"/>
    
    <xsl:param name="movID" as="xs:string" required="yes"/>
    <xsl:param name="musicFilePath" as="xs:string" required="yes"/>
    <xsl:param name="userName" as="xs:string" required="no"/>
    
    <xsl:variable name="musicFile" select="if(doc-available($musicFilePath)) then(doc($musicFilePath)) else()" as="node()?"/>
    <xsl:variable name="musicMdiv" select="if($musicFile) then($musicFile//mei:mdiv) else()" as="node()*"/>
    <xsl:variable name="musicMeasures" select="if($musicFile) then($musicFile//mei:measure) else()" as="node()*"/>
    <xsl:variable name="ediromMeasures" select="if(id($movID)) then(id($movID)//mei:measure) else()" as="node()*"/>
    
    <xsl:template match="/">
        
        <xsl:if test="not($musicFile)">
            <xsl:message terminate="yes">The file at <xsl:value-of select="$musicFilePath"/> coulnd't be found.</xsl:message>
        </xsl:if>
        
        <xsl:if test="not(count($musicFile//mei:mdiv) = 1)">
            <xsl:message terminate="yes">The music file has more than one mei:mdiv. No matching possible.</xsl:message>
        </xsl:if>
        
        <xsl:if test="not(//mei:mdiv[@xml:id = $movID])">
            <xsl:message terminate="yes">There is no mei:mdiv with an xml:id="<xsl:value-of select="$movID"/>".</xsl:message>
        </xsl:if>
        
        <xsl:if test="count($ediromMeasures) != count($musicMeasures)">
            <xsl:message terminate="yes">The music file has a different number of measures. Edirom file: <xsl:value-of select="count($ediromMeasures)"/> measures, music file: <xsl:value-of select="count($musicMeasures)"/> measures.</xsl:message>
        </xsl:if>
        
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:meiHead">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
            <xsl:apply-templates select="$musicFile//mei:encodingDesc"/>
            <xsl:apply-templates select="$musicFile//mei:revisionDesc"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:sourceDesc//mei:pubStmt">
        <xsl:copy-of select="."/>
        <xsl:apply-templates select="$musicFile//mei:sourceDesc//mei:notesStmt"/>
    </xsl:template>
    
    <xsl:template match="mei:change[not(following-sibling::mei:change)]">
        <xsl:copy-of select="."/>
        <xsl:variable name="newN" select="number(@n) + 1"/>
        <change n="{$newN}" xmlns="http://www.music-encoding.org/ns/mei" xsl:exclude-result-prefixes="mei">
            <respStmt><xsl:if test="$userName"><persName><xsl:value-of select="$userName"/></persName></xsl:if></respStmt>
            <changeDesc>
                <p>Automatically merged Edirom MEI file with measure positions with MEI file 
                    derived from MusicXML.</p>
            </changeDesc>
            <date><xsl:value-of select="substring(string(current-date()),1,10)"/></date>
        </change>
    </xsl:template>
    
    <xsl:template match="mei:mdiv[@xml:id != $movID]">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="mei:facsimile">
        <xsl:copy-of select="."/>
    </xsl:template>
    
    <xsl:template match="mei:mdiv[@xml:id = $movID]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="$musicMdiv//mei:score"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="mei:measure">
        
        <xsl:variable name="musicIndex" select="index-of($musicMeasures/@xml:id,@xml:id)"/>
        <xsl:variable name="ediromMeasure" select="$ediromMeasures[$musicIndex]"/>
        
        <xsl:copy>
            <xsl:apply-templates select="$ediromMeasure/@*"/>
            <xsl:apply-templates select="@* except (@xml:id, @n)"/>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>