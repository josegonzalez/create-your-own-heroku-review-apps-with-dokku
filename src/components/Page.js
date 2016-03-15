import React from 'react';
import compose from 'recompose/compose';
import defaultProps from 'recompose/defaultProps';
import Markdown from 'react-components-markdown';
import pageStyles from './Page.sass';
import mdContent from '../../README.md';
import githubCss from 'github-markdown-css/github-markdown.css';
import hlJsCss from 'highlight.js/styles/github.css';

export const page = ({ styles, content, markdownStyles }) => (
  <div className={styles.main}>
    <Markdown styles={markdownStyles}>
      {content}
    </Markdown>
  </div>
);

export const pageHOC = compose(
  defaultProps({
    styles: pageStyles,
    markdownStyles: {
      ...githubCss,
      ...hlJsCss,
    },
    content: mdContent,
  }),
);

export default pageHOC(page);
