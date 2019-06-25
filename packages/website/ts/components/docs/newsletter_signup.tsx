import { Link } from '@0x/react-shared';
import * as _ from 'lodash';
import * as React from 'react';
import styled, { withTheme } from 'styled-components';

import { Button } from 'ts/components/button';
import { SearchInput } from 'ts/components/docs/search_input';
import { Icon } from 'ts/components/icon';
import { Column, FlexWrap, WrapGrid } from 'ts/components/newLayout';
import { ThemeValuesInterface } from 'ts/components/siteWrap';
import { Heading, Paragraph } from 'ts/components/text';
import { colors } from 'ts/style/colors';
import { WebsitePaths } from 'ts/types';
import { constants } from 'ts/utils/constants';

export interface NewsletterSignupProps {
    heading?: string;
    description?: string;
    url?: string;
}

interface WrapperProps {
    isHome?: boolean;
}

export const NewsletterSignup: React.FunctionComponent<NewsletterSignupProps> = (props: NewsletterSignupProps) => (
    <>
        <Wrapper href={props.url}>
            <Heading marginBottom="8px">{props.heading}</Heading>
            <Paragraph marginBottom="25px">{props.description}</Paragraph>
            <InputWrapper>
                <Label htmlFor="emailSignup">Email Address</Label>
                <Input id="emailSignup" type="email" placeholder="Email Address" />
                <Submit>
                    <svg width="22" height="17" viewBox="0 0 22 17" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path
                            opacity=".5"
                            d="M13.066 0l-1.068 1.147 6.232 6.557H0v1.592h18.23l-6.232 6.557L13.066 17l8.08-8.5-8.08-8.5z"
                            fill="#5C5C5C"
                        />
                    </svg>
                </Submit>
            </InputWrapper>
        </Wrapper>
    </>
);

NewsletterSignup.defaultProps = {
    heading: 'Sign up for the Newsletter',
    description: 'Body font about the newseletter',
};

const Wrapper = styled.a<WrapperProps>`
    background-color: ${colors.backgroundLight};
    padding: 40px 30px 50px;
    display: flex;
    justify-content: center;
    flex-direction: column;
    text-align: center;
    margin-bottom: 1.875rem;
`;

const Label = styled.label`
    visibility: hidden;
    opacity: 0;
    position: absolute;
    width: 0;
`;

const InputWrapper = styled.div`
    padding: 0 40px;
    position: relative;
`;

const Input = styled.input`
    background-color: transparent;
    border: 0;
    padding-top: 1rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #cfcfcf;
    font-size: 1.25rem;
    font-weight: 300;
    width: 100%;
    outline: none;
`;

const Submit = styled.button`
    background-color: transparent;
    border: 0;
    cursor: pointer;
    appearance: none;
    position: absolute;
    height: 100%;
    width: 50px;
    right: 40px;
`;
