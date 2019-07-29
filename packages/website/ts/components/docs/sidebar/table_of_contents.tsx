import * as React from 'react';
import styled from 'styled-components';

import { Link } from '@0x/react-shared';

import { colors } from 'ts/style/colors';

import { SidebarWrapper } from 'ts/components/docs/sidebar/sidebar_wrapper';

interface ITableOfContentsProps {
    contents: IContents[];
}

export interface IContents {
    children: IContents[];
    id: string;
    level: number;
    title: string;
}

export const TableOfContents: React.FC<ITableOfContentsProps> = ({ contents }) => {
    return (
        <SidebarWrapper>
            <Contents contents={contents} />
        </SidebarWrapper>
    );
};

const Contents: React.FC<ITableOfContentsProps> = ({ contents }) => {
    return (
        <ContentsList>
            {contents.map(content => {
                const { children, id, title } = content;
                return (
                    <li key={id}>
                        <ContentLink containerId="" to={id}>
                            {title}
                        </ContentLink>
                        {children.length > 0 && <Contents contents={children} />}
                    </li>
                );
            })}
        </ContentsList>
    );
};

const ContentsList = styled.ul`
    li {
        margin-bottom: 1rem;

        &:last-child {
            margin-bottom: 0;
        }
    }

    ul {
        border-left: 1px solid #e3e3e3;
        padding-left: 0.7rem;
        margin-top: 1rem;

        span {
            font-size: 0.7222rem;
            line-height: 1.45;
        }
    }
`;

// Note (piotr): The links could also be styled by using the level prop we get from contents generated from mdx files

const ContentLink = styled(Link)`
    font-size: 0.8333rem;

    span {
        color: ${({ theme }) => theme.paragraphColor};
        transition: color 250ms ease-in-out;
    }

    &.active span {
        color: ${colors.brandDark};
    }
`;
